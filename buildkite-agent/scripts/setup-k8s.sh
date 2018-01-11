#!/usr/bin/env bash

set -eou pipefail

SVC_ACC_PATH=/var/run/secrets/kubernetes.io/serviceaccount/
TOKEN="$(cat ${SVC_ACC_PATH}/token)"

kubectl config set-cluster cfc --server=https://kubernetes.default --certificate-authority=${SVC_ACC_PATH}/ca.crt
kubectl config set-context cfc --cluster=cfc
kubectl config set-credentials user --token=${TOKEN}
kubectl config set-context cfc --user=user
kubectl config use-context cfc
