#!/bin/bash
kubectl create -f https://projectcalico.docs.tigera.io/archive/v3.23/manifests/tigera-operator.yaml
kubectl apply -f install.yaml