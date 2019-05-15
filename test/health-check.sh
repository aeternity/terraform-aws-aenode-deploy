#!/bin/bash

set -Eeuo pipefail

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-ap-southeast-2}

IPS=$(aws ec2 describe-instances --filters "Name=tag:envid,Values=${ENVID:?}" |jq -r '.Reservations[].Instances[].PublicIpAddress')
test -n "$IPS" || (echo "No instances found with envid: ${ENVID} in ${AWS_DEFAULT_REGION} region" >&2; exit 1)

echo "$IPS" | xargs -n 1 -I '{IP}' curl -s -f -S -o /dev/null --retry 8 --retry-connrefused http://{IP}:8080/healthz
