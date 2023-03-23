# Module 02 - Create the Azure Resources

For this workshop we will use the shell scripts to create all needed Azure resources.

The diagram below presents a high-level view of the Azure resources that will be created for this workshop.

## Steps

1. Copy the example setup file that contains the environment variables that will used during the resources creation. You can change the variables according to your needs in order the create a more personalized environment.

   ```bash
   cp aks-prov/setup.env.example aks-prov/setup.env
   ```

   The table below explains each of the important variables of the `setup.env` file.

   | Variable | Default value | Description|
   |---|---|---|
   | `USER_NAME` | <your-name-here> | Enter your name __*__|
   | `PROJECT_NAME` | <your-project-name-here> | Create a name for your project __*__ |
   | `LOCATION` | ("westus" "canadacentral") | Select that locations you want to create the resources |
   | `VNET_ADDRESS_PREFIX` | ("10.0.0.0/16" "10.1.0.0/16") | CIDR for the VNET on each location |
   | `NO_OF_SUBNETS` | 2| Number of subnets in the VNET (do not change) |
   | `SUBNET_CIDR` | 21 | CIDR of the subnets |
   | `K8S_VERSION` | 1.23 | Kubernetes version |
   | `NO_OF_NODES` | 3 | Three is the minimun for REDIS to work |
   | `NODE_VM_SIZE` | ("Standard_B4ms" "Standard_B4ms") | VM type for the nodes on each region |
   | `MAX_PODS` | 110 | Max number of pods (AKS default is 30) |
   | `NETWORK_PLUGIN` |  azure | CNI to be used in the AKS clusters |
   | `OS_DISK_SIZE` | 160 | OS disk size in GB |
   | `DNS_SVC_IP` | ("10.0.24.10" "10.1.24.10") | DNS service IP on each region |
   | `SERVICE_CIDR` | ("10.0.24.0/22" "10.1.24.0/22")| CIDR for the services on each region |
   | `SSH_KEY` | "<path/to/your/public/key.pub>" | Provide your public key to gain access to the nodes |


   > __*__ `USER_NAME` and `PROJECT_NAME` variables will e used to name the majority of the resources, so you can easily distintc them from your other resources.


   ## LOCATION var set as indexed array
####------------------------------------------------------------------------------------ 
USER_NAME=<your-name-here> 
PROJECT_NAME=<your-project-name-here>
LOCATION=("westus" "canadacentral")
####------------------------------------------------------------------------------------

# Vnets
## Notes:
## Set VNET_ADDRESS_PREFIX in the same order as your LOCATION array for the prefixes you want
## Add the vnet prefix for each cluster in the array
####------------------------------------------------------------------------------------
VNET_ADDRESS_PREFIX=("10.0.0.0/16" "10.1.0.0/16")
####------------------------------------------------------------------------------------

# Subnets
## Enter desired number of subnets and the CIDR, subnets will be calculated appropriately and applied for each Vnet
####------------------------------------------------------------------------------------
NO_OF_SUBNETS=2 # Number of subnets desired in the vnet
SUBNET_CIDR=21 # CIDR of each subnet
####------------------------------------------------------------------------------------

#AKS Vars
## Notes:
## NODE_VM_SIZE set as indexed array (incase you hit limits or want different sizes)
## DNS_SVC_IP set as indexed array corresponding to your subnet
## The first subnet will always be picked to create your AKS cluster in:
## so in this example that would be 10.0.0.0/21 for the eastus cluster
####------------------------------------------------------------------------------------
K8S_VERSION=1.23
NO_OF_NODES=3
NODE_VM_SIZE=("Standard_B4ms" "Standard_B4ms") 
MAX_PODS=110
NETWORK_PLUGIN=azure
OS_DISK_SIZE=160
DNS_SVC_IP=("10.0.24.10" "10.1.24.10")
SERVICE_CIDR=("10.0.24.0/22" "10.1.24.0/22")
SSH_KEY="<path/to/your/public/key.pub>"

- Copy the example env variables file ```cp aks-prov/setup.env.example aks-prov/setup.env```  
- Setup yo ur variables in ```aks-prov/setup.env```
- Run the bringup script ```bash aks-prov/create.sh```

```bash
bash aks-prov/create.sh
```

---

next: connect to calico cloud

previous: create resources

