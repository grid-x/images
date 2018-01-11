#!/usr/bin/env bash

set -eou pipefail

CONTEXT=$1
SERVER=$2
CA_CRT=$3
TOKEN=$4

if [[ -z $CONTEXT ]]; then
    echo "context not given"
    echo "exiting..."
    exit 0
fi

if [[ -z $SERVER ]]; then
    echo "server not given"
    echo "exiting..."
    exit 0
fi

if [[ -z $CA_CRT ]]; then
    echo "ca.crt not given"
    echo "exiting..."
    exit 0
fi

if [[ -z $TOKEN ]]; then
    echo "token not given"
    echo "exiting..."
    exit 0
fi

echo $CA_CRT > /tmp/ca.crt

kubectl config set-cluster ${CONTEXT} --server=${SERVER} --certificate-authority=/tmp/ca.crt
kubectl config set-context ${CONTEXT} --cluster=${CONTEXT}
kubectl config set-credentials user --token=${TOKEN}
kubectl config set-context ${CONTEXT} --user=user
kubectl config use-context ${CONTEXT}
