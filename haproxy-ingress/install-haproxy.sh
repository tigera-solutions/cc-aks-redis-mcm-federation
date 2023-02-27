#!/usr/bin/env bash
source setup.env
for i in "${!K8S_CONTEXTS[@]}"
do
    echo "Changing context to K8s cluster ${K8S_CONTEXTS[i]}"
    kubectl config use-context ${K8S_CONTEXTS[i]}
    helm repo add haproxy-ingress https://haproxy-ingress.github.io/charts
    helm install ingress haproxy-ingress/haproxy-ingress --create-namespace --namespace=ingress-controller -f values.yaml
done