#!/usr/bin/env bash
source federation-functions.sh

# Make sure kubectl is installed
if ! [ -x "$(command -v kubectl)" ]; then
  echo 'Error: kubectl is required and was not found' >&2
  exit 1
fi

apply_rbac
generate_kubeconfigs
create_secrets
create_remote_configs
apply_remote_configs