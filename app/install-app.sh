#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/setup.env

for i in "${!K8S_CONTEXTS[@]}"
  do
    echo "Changing context to K8s cluster ${K8S_CONTEXTS[i]}"
    kubectl config use-context ${K8S_CONTEXTS[i]}
    kubectl get namespace | grep -q "^$NAMESPACE " || kubectl create namespace $NAMESPACE
    kubectl -n $NAMESPACE apply -f $SCRIPT_DIR/hipstershop.yaml
  done