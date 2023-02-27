#!/usr/bin/env bash

# Source all env variables
source setup.env


# Resource Group functions
create_rg () {
    for location in "${LOCATION[@]}"
    do
        # Create resource groups for each location
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-$location
        echo Creating resource group with name $RG_NAME in region $location
        az group create --name $RG_NAME --location $location
    done
}

delete_rg () {
    echo "Deleting all RGs"
    for location in "${LOCATION[@]}"
    do
        # Create resource groups for each location
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-$location
        echo Deleting resource group with name $RG_NAME in region $location
        az group delete --name $RG_NAME --yes --no-wait
    done
}


get_rg () {
    az group list -otable | grep rg-$USER_NAME
}


# Vnet/subnets functions
create_network () {
    for i in "${!LOCATION[@]}"
    do
        # Create vnets and subnets for each location
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        echo Creating Vnet with name $VNET_NAME, prefix ${VNET_ADDRESS_PREFIX[i]}, adding to resource group $RG_NAME in region ${LOCATION[i]} 
        az network vnet create --name $VNET_NAME --resource-group $RG_NAME --address-prefixes ${VNET_ADDRESS_PREFIX[i]}
        # Calculate subnet prefixes
        POWER=$((32-$SUBNET_CIDR))
        HOSTS=$((2 ** $POWER-2))
        HOSTS_ARG=$(yes $HOSTS | head -n$NO_OF_SUBNETS | xargs echo)
        subnets=$(ipcalc ${VNET_ADDRESS_PREFIX[i]} -b -n -s $HOSTS_ARG | grep Network | grep $SUBNET_CIDR | awk '{print $2}')
        set -f
        declare -a "subnets$((i+1))_array=($subnets)"
        declare -n subnet_array="subnets$((i+1))_array"        
        for j in "${!subnet_array[@]}"
        do
            SUBNET_NAME=subnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}-$((j+1))
            echo Creating subnet with name $SUBNET_NAME, prefix ${subnet_array[j]} into Vnet $VNET_NAME
            az network vnet subnet create --address-prefix ${subnet_array[j]} --name $SUBNET_NAME --resource-group $RG_NAME --vnet-name $VNET_NAME
        done
    done
}


get_network () {
    for i in "${!LOCATION[@]}"
    do
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        az network vnet show -g $RG_NAME -n $VNET_NAME -otable
        az network vnet subnet list -g $RG_NAME --vnet-name $VNET_NAME -otable
    done
}

delete_network () {
    for i in "${!LOCATION[@]}"
    do
        # Delete vnets and subnets for each location
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        #az network vnet create --name $VNET_NAME --resource-group $RG_NAME --address-prefixes ${VNET_ADDRESS_PREFIX[i]} --no-wait
        # Calculate subnet prefixes
        POWER=$((32-$SUBNET_CIDR))
        HOSTS=$((2 ** $POWER-2))
        HOSTS_ARG=$(yes $HOSTS | head -n$NO_OF_SUBNETS | xargs echo)
        subnets=$(ipcalc ${VNET_ADDRESS_PREFIX[i]} -b -n -s $HOSTS_ARG | grep Network | grep $SUBNET_CIDR | awk '{print $2}')
        set -f
        declare -a "subnets$((i+1))_array=($subnets)"
        declare -n subnet_array="subnets$((i+1))_array"        
        #echo The subnets for $VNET_NAME are "${subnet_array[*]}"
        for j in "${!subnet_array[@]}"
        do
            SUBNET_NAME=subnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}-$((j+1))
            echo Deleting subnet with name $SUBNET_NAME, prefix ${subnet_array[j]} from Vnet $VNET_NAME
            az network vnet subnet delete --name $SUBNET_NAME --resource-group $RG_NAME --vnet-name $VNET_NAME
        done
        echo Deleting Vnet with name $VNET_NAME, prefix ${VNET_ADDRESS_PREFIX[i]}, removing from resource group $RG_NAME in region ${LOCATION[i]}
        az network vnet delete --name $VNET_NAME --resource-group $RG_NAME 
    done
}

# Vnet Peering functions
create_peering () {
    len=${#LOCATION[@]}
    NEW_LOCATION=()  
    for (( i=0; i<$len; i++))
    do
        # Create peerings for each location
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        VNET_ID=$(az network vnet show --resource-group $RG_NAME --name $VNET_NAME --query id --out tsv)   
        NEW_LOCATION+=(${LOCATION[(i+1) % $len]})
        REMOTE_VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${NEW_LOCATION[i]}
        REMOTE_RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${NEW_LOCATION[i]}
        REMOTE_VNET_ID=$(az network vnet show --resource-group $REMOTE_RG_NAME --name $REMOTE_VNET_NAME --query id --out tsv)
        az network vnet peering create -g $RG_NAME -n ${LOCATION[i]}-to-${NEW_LOCATION[i]} --vnet-name $VNET_NAME --remote-vnet $REMOTE_VNET_ID --allow-vnet-access --allow-forwarded-traffic
        az network vnet peering create -g $REMOTE_RG_NAME -n ${NEW_LOCATION[i]}-to-${LOCATION[i]} --vnet-name $REMOTE_VNET_NAME --remote-vnet $VNET_ID --allow-vnet-access --allow-forwarded-traffic
        #echo
    done
}

get_peering() {
    for i in "${!LOCATION[@]}"
    do
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        az network vnet peering list -g $RG_NAME --vnet-name $VNET_NAME -otable --only-show-errors
    done
}

delete_peering () {
    len=${#LOCATION[@]}
    NEW_LOCATION=()
    for (( i=0; i<$len; i++))
    do
        # Create peerings for each location
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}   
        NEW_LOCATION+=(${LOCATION[(i+1) % 3]})
        REMOTE_VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${NEW_LOCATION[i]}
        REMOTE_RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${NEW_LOCATION[i]}
        echo az network vnet peering delete -g $RG_NAME -n ${LOCATION[i]}-to-${NEW_LOCATION[i]} --vnet-name $VNET_NAME
        echo az network vnet peering delete -g $REMOTE_RG_NAME -n ${NEW_LOCATION[i]}-to-${LOCATION[i]} --vnet-name $REMOTE_VNET_NAME
        echo
    done
}

create_aks_cluster () {
    for i in "${!LOCATION[@]}"
    do
        # Variables
        CLUSTER_NAME=aks-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        NODE_RG_NAME=noderg-$PROJECT_NAME-${LOCATION[i]}
        VNET_NAME=vnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        SUBNET_NAME=subnet-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}-1
        DNS_PREFIX=$PROJECT_NAME-${LOCATION[i]}
        VNET_SUBNET_ID=$(az network vnet subnet show -g $RG_NAME -n $SUBNET_NAME --vnet-name $VNET_NAME --query id --out tsv)
        # AKS cluster create
        az aks create \
            --resource-group $RG_NAME \
            --node-resource-group $NODE_RG_NAME \
            --name $CLUSTER_NAME \
            --kubernetes-version $K8S_VERSION \
            --location ${LOCATION[i]} \
            --node-count $NO_OF_NODES \
            --node-vm-size ${NODE_VM_SIZE[i]} \
            --node-osdisk-size $OS_DISK_SIZE \
            --max-pods $MAX_PODS \
            --ssh-key-value $SSH_KEY \
            --network-plugin $NETWORK_PLUGIN \
            --vnet-subnet-id "$VNET_SUBNET_ID" \
            --service-cidr ${SERVICE_CIDR[i]} \
            --dns-service-ip ${DNS_SVC_IP[i]} 
    done
}

delete_aks_cluster () {
    for i in "${!LOCATION[@]}"
    do
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        CLUSTER_NAME=$(az aks list -g $RG_NAME -otsv --query '[].[name]' --only-show-errors)
        readarray -t clustername_array <<<"$CLUSTER_NAME"
        declare -p clustername_array
        echo ${clustername_array[0]}
        for j in "${!clustername_array[@]}"
        do
            echo Deleting AKS cluster named ${clustername_array[j]} in resource group $RG_NAME
            az aks delete -n ${clustername_array[j]} -g $RG_NAME --yes
        done
    done
}

get_aks_credentials () {
    for i in "${!LOCATION[@]}"
    do
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        CLUSTER_NAME=$(az aks list -g $RG_NAME -otsv --query '[].[name]' --only-show-errors)
        readarray -t clustername_array <<<"$CLUSTER_NAME"
        declare -p clustername_array >/dev/null
        for j in "${!clustername_array[@]}"
        do
            az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME --only-show-errors
            echo
        done
    done
}

get_aks_cluster () {
    for i in "${!LOCATION[@]}"
    do
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        CLUSTER_NAME=$(az aks list -g $RG_NAME -otsv --query '[].[name]' --only-show-errors)
        readarray -t clustername_array <<<"$CLUSTER_NAME"
        declare -p clustername_array >/dev/null
        az aks list -g $RG_NAME -otable --only-show-errors
        for j in "${!clustername_array[@]}"
        do
            az aks nodepool list -g $RG_NAME --cluster-name ${clustername_array[j]} --only-show-errors | grep code
        done
    done
}

start_aks_cluster () {
    for i in "${!LOCATION[@]}"
    do
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        CLUSTER_NAME=$(az aks list -g $RG_NAME -otsv --query '[].[name]' --only-show-errors)
        readarray -t clustername_array <<<"$CLUSTER_NAME"
        declare -p clustername_array >/dev/null
        for j in "${!clustername_array[@]}"
        do
            echo Starting cluster named ${clustername_array[j]}
            az aks start -g $RG_NAME -n ${clustername_array[j]} --no-wait --only-show-errors
            az aks nodepool list -g $RG_NAME --cluster-name ${clustername_array[j]} --only-show-errors | grep code
        done
        az aks list -g $RG_NAME -otable --only-show-errors
    done    
}

stop_aks_cluster () {
    for i in "${!LOCATION[@]}"
    do
        RG_NAME=rg-$USER_NAME-$PROJECT_NAME-${LOCATION[i]}
        CLUSTER_NAME=$(az aks list -g $RG_NAME -otsv --query '[].[name]' --only-show-errors)
        readarray -t clustername_array <<<"$CLUSTER_NAME"
        declare -p clustername_array >/dev/null
        for j in "${!clustername_array[@]}"
        do
            echo Stopping cluster named ${clustername_array[j]}
            az aks stop -g $RG_NAME -n ${clustername_array[j]} --no-wait --only-show-errors
            az aks nodepool list -g $RG_NAME --cluster-name ${clustername_array[j]} --only-show-errors | grep code
        done
        az aks list -g $RG_NAME -otable --only-show-errors
    done   
}