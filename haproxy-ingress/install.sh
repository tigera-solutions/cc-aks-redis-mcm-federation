#!/usr/bin/env bash
helm repo add haproxy-ingress https://haproxy-ingress.github.io/charts
helm install ingress haproxy-ingress/haproxy-ingress --create-namespace --namespace=ingress-controller -f values.yaml