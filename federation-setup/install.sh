#!/bin/bash
kubectl apply -f federation-rem-rbac-kdd.yaml
kubectl apply -f federation-remote-sa.yaml

source create-remote-cluster-kubeconfigs.sh