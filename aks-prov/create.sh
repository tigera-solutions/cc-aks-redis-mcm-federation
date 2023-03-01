#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/cluster-functions.sh

if ! command -v ipcalc &> /dev/null
then
    echo -e '\033[7;31mERROR\033[0m: \033[1;36mipcalc\033[0m could not be found. Is it installed?'
    exit
fi

# Create RGs
create_rg
echo "Sleeping for 5 seconds to wait for the RGs to be created"
sleep 5
get_rg

# Create Vnets and subnets
create_network
echo "Sleeping for 5 seconds to wait for the vnets and subnets to be created"
sleep 5
get_network

# Setup Vnet peering
create_peering
echo "Sleeping for 5 seconds to wait for the vnets to be peered"
sleep 5
get_peering

# Create AKS cluster
create_aks_cluster
echo "Sleeping for 5 seconds to wait for the AKS clusters to finish creating"
sleep 5
get_aks_cluster

Get credentials 
# There needs to be a while loop written here to not call the function until the cluster is done creating
# and has generated a kubeconfig file
echo "Getting AKS credentials"
echo "If this fails and you can't get credentials please check the status of the AKS cluster is created then try again"
get_aks_credentials