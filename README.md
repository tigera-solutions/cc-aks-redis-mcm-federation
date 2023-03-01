# cc-aks-redis-mcm-federation

> :warning: **This repo is purely a work-in-progress(WIP) and is in active development. Other than contributors, anyone else
>should probably not try the stuff in this repo and expect it to work as is until it's finished and ready!**

## Bringup Sequence

### Create Azure Resources

- Copy the example env variables file ```cp aks-prov/setup.env.example aks-prov/setup.env```  
- Setup your variables in ```aks-prov/setup.env```
- Run the bringup script ```bash aks-prov/create.sh```

```bash
bash aks-prov/create.sh
```

### Connect to CC

We know how to do this

### Deploy HAProxy-Ingress

- Copy the example env variables file ```cp haproxy-ingress/setup.env.example haproxy-ingress/setup.env```
- Setup the variables in your ```haproxy-ingress/setup.env```
- Run the bringup script ```bash haproxy-ingress/install-haproxy.sh```

```bash
bash haproxy-ingress/install.sh
```

Check the internal Azure AKS LB assigned the svc an EXTERNAL-IP off the Vnet subnet

```bash
kubectl get svc -n ingress-controller
```

### Deploy Redis on each cluster

The install bash script assumes you have the context names for each kubeconfig file and they're setup to be unique (AKS does this already and merges them properly)

- Copy the example env variables file ```cp redis/setup.env.example redis/setup.env```
- Setup the variables in your ```redis/setup.env```
- Run the script at ```redis/install-rec.sh```
  

```bash
bash redis/install-rec.sh
```

- The State should be running and Spec Status Valid (will take a while to deploy the StatefulSets)
- Check this on all clusters

```bash
~/w/azure-aks-mcm-federation main wip !53 ?5 ❯ kubectl get rec                                                       
NAME            NODES   VERSION     STATE     SPEC STATUS   LICENSE STATE   SHARDS LIMIT   LICENSE EXPIRATION DATE   AGE
demo-clusterb   3       6.2.18-65   Running   Valid         Valid           4              2023-03-19T20:36:00Z      3h32m
```


- Install the REC admission controller by running the script on each cluster
  (New script that takes care of this on all cluster contexts WIP)

```bash
bash redis/webhook/install-ac.sh
```

- Test the admisson controller on each cluster by trying to create an invalid spec

```bash
bash redis/webhook/test-ac.sh
```

You should get a result that says something like this

```
Error from server: error when creating "STDIN": admission webhook "redb.admission.redislabs" denied the request: 'illegal' is an invalid value for 'eviction_policy'
```


>**Reference**: https://docs.redis.com/latest/kubernetes/deployment/quick-start/


### Creating the active-active Redis db

>**Reference**: https://docs.redis.com/latest/kubernetes/re-clusters/create-aa-database/

#### Setting up Azure Private DNS Zone and records

- First you need to setup your DNS aliases in Azure Private DNS for each cluster 
- There is already an RG and zone setup for this in Azure, feel free to create the DNS A records in there and use the same zone if you want. 
- Wildcards can be used but I messed up so I created A entries for each name (oops)

![zone](redis/images/private_zones.png)

![names](redis/images/dns_names.png)

- The other thing to ensure is that you have added the required Vnets of all the clusters the DNS zone to the virtual network links page so that the cluster vnets can actually resolve your DNS names in the zone.

![vnet_links](redis/images/vnet_links.png)


#### Getting the active-active config parameters ready

- Open up the file redis/activeconfig.txt in your text editor
- Get all the values for all 3 clusters using the reference link as an example
- Get the crdb command ready with all values (as shown at the end of activeconfig.txt)
- Bash into one of the rec pods on any one cluster and run the crdb command

```bash
~/workspace/azure-aks-mcm-federation/redis main wip !16 ?5 ❯ kubectl exec -it demo-clustera-0 -- /bin/bash                                                                   ⎈ aks-kartik-cc-mcm-workshop-eastus/redis 15:52:10
Defaulted container "redis-enterprise-node" out of: redis-enterprise-node, bootstrapper
redislabs@demo-clustera-0:/opt$ crdb-cli crdb create \
>   --name testdb \
>   --memory-size 500MB \
>   --encryption yes \
>   --instance fqdn=demo-clustera.redis.svc.cluster.local,url=https://api-clustera.tigera.redisdemo.com,username=demo@redislabs.com,password=xia3cG8b,replication_endpoint=testdb-clustera.tigera.redisdemo.com:443,replication_tls_sni=testdb-clustera.tigera.redisdemo.com \
>   --instance fqdn=demo-clusterb.redis.svc.cluster.local,url=https://api-clusterb.tigera.redisdemo.com,username=demo@redislabs.com,password=IHqnWuvi,replication_endpoint=testdb-clusterb.tigera.redisdemo.com:443,replication_tls_sni=testdb-clusterb.tigera.redisdemo.com \
>   --instance fqdn=demo-clusterc.redis.svc.cluster.local,url=https://api-clusterc.tigera.redisdemo.com,username=demo@redislabs.com,password=9q44NKmF,replication_endpoint=testdb-clusterc.tigera.redisdemo.com:443,replication_tls_sni=testdb-clusterc.tigera.redisdemo.com
Task c28d64db-c652-4530-afa0-d539d001f28f created
  ---> CRDB GUID Assigned: crdb:b787a586-c212-4de5-93cd-aff32190a972
  ---> Status changed: queued -> started
  ---> Status changed: started -> finished
```

- If it all went well then status should go from started -> finished
- Check that ingress rule got created for your db (testdb in this example)

```bash
~/workspace/azure-aks-mcm-federation/redis main wip !16 ?5 ❯ kubectl get ingress                                                               28s ⎈ aks-kartik-cc-mcm-workshop-eastus/redis 15:52:39
NAME            CLASS    HOSTS                                  ADDRESS     PORTS   AGE
demo-clustera   <none>   api-clustera.tigera.redisdemo.com      10.0.1.76   80      2d5h
testdb          <none>   testdb-clustera.tigera.redisdemo.com   10.0.1.76   80      23s
```


### Testing that replication works

- Change context to your first cluster and bash into one of the db pods 

```bash
kubectl exec -it -n redis demo-clustera-0 -- /bin/bash
```

- Connect to db ClusterIP service for your cluster 

```bash
root@demo-clustera-0:/data# redis-cli -h testdb -p 19138
testdb:19138>
testdb:19138> set Name "Kartik"
OK
testdb:19138> set State "Something"
OK
```

- Change context to your second cluster and bash into one of the db pods
- When you get the Keys you created, you should see the values got replicated to this cluster's db 

```bash
root@demo-clusterb-0:/data# redis-cli -h testdb -p 19138
testdb:19138> get Name
"Kartik"
testdb:19138> get State
"Something"
```

### Federation Setup

>**Reference**: https://docs.tigera.io/calico-cloud/multicluster/kubeconfig

- Copy the example env variables file ```cp federation-setup/setup.env.example federation-setup/setup.env```
- Setup the variables in your ```federation-setup/setup.env```
- Run the bringup script ```bash federation-setup/install-federation.sh```

#### Verifying that federated endpoints got created  

##### Linux Users

- If your laptop/machine is Linux-based or you are running a Linux VM that is setup with access to your K8s clusters, then just download calicoq CLI tool from the [Calico docs](https://docs.tigera.io/calico-enterprise/3.15/operations/clis/calicoq/installing#install-calicoq-as-a-binary-on-a-single-host)
- Run the following command against your clusters 

```bash
calicoq eval "all()"
```

  You should get something like this where you see remote endpoints prefixed by the RemoteClusterConfig name you created in the earlier steps as well as local endpoints with the format host-a/endpoint:

  ```bash
  (Lots of remote endpoints)
  Workload endpoint calico-demo-remote-canadacentral/aks-nodepool1-86764462-vmss000000/k8s/redis.demo-clusterb-services-rigger-d45c6c4-cp4g8/eth0
  Workload endpoint calico-demo-remote-canadacentral/aks-nodepool1-86764462-vmss000000/k8s/redis.demo-clusterb-1/eth0
  Workload endpoint calico-demo-remote-canadacentral/aks-nodepool1-86764462-vmss000001/k8s/redis.demo-clusterb-0/eth0
  Workload endpoint calico-demo-remote-canadacentral/aks-nodepool1-86764462-vmss000002/k8s/redis.demo-clusterb-2/eth0
  ```

##### MacOS/Windows Users

- If your laptop/machine is Darwin/MacOS or you use WSL, then we have to do things the hard way (REALLY annoying and bad security practice) by using a privileged debug pod on one of the cluster nodes to temporaily install calicoq and do our verification there because calicoq does not have a MacOS/Darwin binary yet. Just spin up a Linux VM anyway is the recommended method but read further if you really want to do this on Mac/Windows.

- Switch to your cluster context
- Get the nodename of one of the worker nodes and save it in a variable

```bash
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="Hostname")].address}'| awk '{print $1;}')
```

- Spin up a debug privileged pod

```bash
kubectl debug node/$NODE_NAME -it --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11
```

- In the pod, get to host namespace as root

```bash
chroot /host
```

- Grab the calicoq binary and install it

```bash
cd /usr/local/bin
curl -o calicoq -O -L https://downloads.tigera.io/ee/binaries/v3.15.1/calicoq
chmod +x calicoq
```

- Create the config file for it 

```bash
vi /etc/calico/calicoctl.cfg
```

Paste in the following: 

```yaml
apiVersion: projectcalico.org/v3
kind: CalicoAPIConfig
metadata:
spec:
  datastoreType: "kubernetes"
  kubeconfig: "/.kube/config"
```

- Create the /.kube/config file, put your config file into it

```bash
mkdir /.kube
vi /.kube/config
```

Paste your kubeconfig for the cluster from your laptop's ~/.kube/config (or wherever you have it), save the file.

- Now run calicoq

```bash
calicoq eval "all()"
```

  You should get something like this where you see remote endpoints prefixed by the RemoteClusterConfig name you created in the earlier steps as well as local endpoints with the format host-a/endpoint:

  ```bash
  (Lots of remote endpoints)
  Workload endpoint calico-demo-remote-canadacentral/aks-nodepool1-86764462-vmss000000/k8s/redis.demo-clusterb-services-rigger-d45c6c4-cp4g8/eth0
  Workload endpoint calico-demo-remote-canadacentral/aks-nodepool1-86764462-vmss000000/k8s/redis.demo-clusterb-1/eth0
  Workload endpoint calico-demo-remote-canadacentral/aks-nodepool1-86764462-vmss000001/k8s/redis.demo-clusterb-0/eth0
  Workload endpoint calico-demo-remote-canadacentral/aks-nodepool1-86764462-vmss000002/k8s/redis.demo-clusterb-2/eth0
  ```

- Yup, that was real easy on a non-Linux laptop /s

> :warning: **SUPER IMPORTANT**: Delete your privileged debug pod once the actual debugging is done!


Let's install the hispershop from this repo.

```bash
kubectl apply -f app
```

## Teardown

- Reverse all the config for federation (if done)

```bash
bash federation-setup/teardown-federation.sh
```

- Run the teardown script to delete all the Azure resources

```bash
bash aks-prov/destroy.sh
```


## Changelog/Need to do

### Feb 28, 2023

- Heavy edits to federation setup and teardown scripts and flow in a new branch, needs to be tested

### Feb 17, 2023

- Configure Hipstershop service to talk to redis and do its things, check that db is getting seeded
- Policies
- Demo flow