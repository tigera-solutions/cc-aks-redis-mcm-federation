#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/cluster-functions.sh

# Delete AKS cluster
delete_aks_cluster
echo "Sleeping for 5 seconds to wait for the AKS delete to go thru"
sleep 5
get_aks_cluster

# Delete Vnet peerings
delete_peering
echo "Sleeping for 5 seconds to delete the Vnet peerings"
sleep 5
get_peering

# Delete Vnets and subnets
delete_network
echo "Sleeping for 5 seconds to delete the network and subnets"
sleep 5
get_network

# Delete RGs
delete_rg
echo "Sleeping for 5 seconds to wait for the RGs to be deleted"
sleep 5
get_rg