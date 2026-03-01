#!/usr/bin/env bash
# Usage: source ./aws-export.sh

AWS_PROFILE=awsadmin
AWS_REGION=us-east-2

echo "Logging in to AWS SSO..."
aws sso login --profile "$AWS_PROFILE"

echo "Exporting credentials..."
eval "$(aws configure export-credentials --profile "$AWS_PROFILE" --format env)"

export AWS_REGION="$AWS_REGION"
export AWS_B64ENCODED_CREDENTIALS
AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)

echo "Done. Credentials exported:"
echo "  AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:0:8}..."
echo "  AWS_SECRET_ACCESS_KEY=***"
echo "  AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:0:8}..."
echo "  AWS_REGION=$AWS_REGION"
echo "  AWS_B64ENCODED_CREDENTIALS=${AWS_B64ENCODED_CREDENTIALS:0:8}..."
