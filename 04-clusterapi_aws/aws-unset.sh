#!/usr/bin/env bash
# Usage: source ./aws-unset.sh

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_REGION
unset AWS_B64ENCODED_CREDENTIALS

echo "AWS credentials unset."
