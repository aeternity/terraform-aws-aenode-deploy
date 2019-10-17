#!/bin/bash

set -Eeuo pipefail

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-ap-southeast-2}

health_check () {
    API_ADDR=$1
    echo "Checking" $API_ADDR

    # Basic health check endpoint
    curl -sSf -o /dev/null --retry 8 --retry-connrefused http://${API_ADDR}:8080/healthz

    # External API
    curl -sSf -o /dev/null --retry 8 --retry-connrefused http://${API_ADDR}:3013/v2/status

    # Internal API (dry-run)
    EXT_STATUS=$(curl -sS -o /dev/null --retry 8 --retry-connrefused \
        -X POST -H "Content-type: application/json" -d '{"txs": []}' \
        -w "%{http_code}" \
        http://${API_ADDR}:3113/v2/debug/transactions/dry-run)
    [ $EXT_STATUS -eq 200 ]

    # State Channels WebSocket API
    WS_STATUS=$(curl -sS -o /dev/null --retry 8 --retry-connrefused \
        -w "%{http_code}" \
        http://${API_ADDR}:3014/channel?role=initiator)
    [ $WS_STATUS -eq 426 ]
}

export -f health_check
IPS=$(aws ec2 describe-instances \
 --query 'Reservations[*].Instances[*].PublicIpAddress' \
 --filters Name=tag:envid,Values=${ENVID:?} Name=instance-state-code,Values=0,16 \
 --output text)
test -n "$IPS" || (echo "No instances found with envid: ${ENVID} in ${AWS_DEFAULT_REGION} region" >&2; exit 1)
echo "$IPS" | xargs -n 1 -I '{IP}' bash -c 'health_check "{IP}"'
