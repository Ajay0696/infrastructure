###############################################################################
# Data sources
###############################################################################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_caller_identity" "current" {}

###############################################################################
# User data – rendered from external shell template files
# Shell variables use $VAR (no braces) so they are not mistaken for Terraform
# template directives. Only the top-level variable block uses ${var} syntax
# (those are the templatefile() input variables).
###############################################################################
locals {
  controlplane_userdata = base64encode(templatefile("${path.module}/scripts/controlplane.sh.tpl", {
    name_prefix     = local.name_prefix
    region          = local.region
    nlb_dns         = module.lb.nlb_dns_name
    k8s_version     = local.k8s_version
    pod_cidr        = local.pod_network_cidr
    service_cidr    = local.service_cidr
    api_server_port = tostring(local.api_server_port)
  }))

  worker_userdata = base64encode(templatefile("${path.module}/scripts/worker.sh.tpl", {
    name_prefix = local.name_prefix
    region      = local.region
    k8s_version = local.k8s_version
  }))
}

###############################################################################
# IAM – Control Plane
###############################################################################
resource "aws_iam_role" "controlplane" {
  name = "${local.name_prefix}_controlplane-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "controlplane" {
  name = "${local.name_prefix}_controlplane-policy"
  role = aws_iam_role.controlplane.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # SSM – store/retrieve kubeadm bootstrap tokens
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:DeleteParameter",
        ]
        Resource = "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/${local.name_prefix}/*"
      },
      # EC2 – cloud provider integration
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeVpcs",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DeleteVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
        ]
        Resource = "*"
      },
      # ELB – Kubernetes LoadBalancer service type
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:*"]
        Resource = "*"
      },
      # ASG – Cluster Autoscaler
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes",
        ]
        Resource = "*"
      },
    ]
  })
}

# SSM Session Manager – shell access without opening SSH to the internet
resource "aws_iam_role_policy_attachment" "controlplane_ssm" {
  role       = aws_iam_role.controlplane.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "controlplane" {
  name = "${local.name_prefix}_controlplane-profile"
  role = aws_iam_role.controlplane.name
}

###############################################################################
# IAM – Worker Nodes
###############################################################################
resource "aws_iam_role" "worker" {
  name = "${local.name_prefix}_worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "worker" {
  name = "${local.name_prefix}_worker-policy"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # SSM – fetch join command at boot
      {
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/${local.name_prefix}/*"
      },
      # ECR – pull container images
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Resource = "*"
      },
      # EC2 – node registration with cloud provider
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances", "ec2:DescribeRegions"]
        Resource = "*"
      },
    ]
  })
}

# SSM Session Manager – shell access without opening SSH to the internet
resource "aws_iam_role_policy_attachment" "worker_ssm" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "worker" {
  name = "${local.name_prefix}_worker-profile"
  role = aws_iam_role.worker.name
}

###############################################################################
# Security Groups
###############################################################################

# Shared cluster SG – attached to every node; allows all intra-cluster traffic
# required by Calico VXLAN and kubelet/etcd communication.
resource "aws_security_group" "cluster" {
  name        = "${local.name_prefix}_cluster-sg"
  description = "Allow all traffic between cluster nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Intra-cluster: all protocols"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}_cluster-sg"
  })
}

# Control plane SG – API server + SSH open (public subnet, learning environment)
resource "aws_security_group" "controlplane" {
  name        = "${local.name_prefix}_controlplane-sg"
  description = "Control plane API server access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "API server"
    from_port   = local.api_server_port
    to_port     = local.api_server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}_controlplane-sg"
  })
}

# Worker SG – NodePort + SSH open (public subnet, learning environment)
resource "aws_security_group" "worker" {
  name        = "${local.name_prefix}_worker-sg"
  description = "Worker nodes access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "NodePort services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}_worker-sg"
  })
}

###############################################################################
# Control Plane ASG
###############################################################################
module "controlplane" {
  source = "../modules/aws_asg"

  name_prefix  = local.name_prefix
  role         = "controlplane"
  cluster_name = local.cluster_name

  ami_id        = data.aws_ami.ubuntu.id
  instance_type = local.instance_type
  key_name      = local.key_name

  subnet_ids = module.vpc.public_subnet_ids
  security_group_ids = [
    aws_security_group.cluster.id,
    aws_security_group.controlplane.id,
  ]

  iam_instance_profile_name = aws_iam_instance_profile.controlplane.name

  desired_capacity = local.controlplane_desired
  min_size         = local.controlplane_min
  max_size         = local.controlplane_max

  # Register control plane with the NLB so the API is reachable
  target_group_arns = [module.lb.target_group_arn]

  user_data        = local.controlplane_userdata
  root_volume_size = 50

  tags = local.common_tags
}

###############################################################################
# Worker Nodes ASG
###############################################################################
module "workers" {
  source = "../modules/aws_asg"

  name_prefix  = local.name_prefix
  role         = "worker"
  cluster_name = local.cluster_name

  ami_id        = data.aws_ami.ubuntu.id
  instance_type = local.instance_type
  key_name      = local.key_name

  subnet_ids = module.vpc.public_subnet_ids
  security_group_ids = [
    aws_security_group.cluster.id,
    aws_security_group.worker.id,
  ]

  iam_instance_profile_name = aws_iam_instance_profile.worker.name

  desired_capacity = local.worker_desired
  min_size         = local.worker_min
  max_size         = local.worker_max

  user_data        = local.worker_userdata
  root_volume_size = 50

  tags = local.common_tags
}

###############################################################################
# Outputs
###############################################################################
output "nlb_dns_name" {
  description = "Public NLB DNS – use this as your kubeconfig server address"
  value       = module.lb.nlb_dns_name
}

output "controlplane_asg_name" {
  description = "Control plane Auto Scaling Group name"
  value       = module.controlplane.asg_name
}

output "worker_asg_name" {
  description = "Worker Auto Scaling Group name"
  value       = module.workers.asg_name
}
