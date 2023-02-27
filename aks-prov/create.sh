#!/usr/bin/env bash
source cluster-functions.sh

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