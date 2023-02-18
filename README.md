# cc-aks-redis-mcm-federation

> :warning: **This repo is purely a work-in-progress(WIP) and is in active development. Other than contributors, anyone else
>should probably not try the stuff in this repo and expect it to work as is until it's finished and ready!**

## Bringup Sequence

### Create Azure Resources

- Setup your variables in aks-prov/setup.env

```bash
bash aks-prov/create.sh
```

## Connect to CC

We know how to do this

## Deploy HAProxy-Ingress

```bash
bash haproxy-ingress/install.sh
```

Check the internal Azure AKS LB assigned the svc an EXTERNAL-IP off the Vnet subnet

```bash
kubectl get svc -n ingress-controller
```

## Deploy Redis on each cluster

The install bash script assumes you have the context names for each kubeconfig file and they're setup to be unique (AKS does this already and merges them properly)

- Setup the variables including your context names in redis/install-rec.sh
- Run the script
  

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


## Creating the active-active Redis db

>**Reference**: https://docs.redis.com/latest/kubernetes/re-clusters/create-aa-database/

- First you need to setup your DNS aliases in Azure Private DNS for each cluster 
- There is already an RG and zone setup for this in Azure, feel free to create the DNS A records in there and use the same zone if you want. 
- Wildcards can be used but I messed up so I created A entries for rach name (oops)

![zone](redis/images/private_zones.png)

![names](redis/images/dns_names.png)

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


## Testing that replication works

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

- That's it for now


## Need to do

- Configure Hipstershop service to talk to redis and do its things, check that db is getting seeded
- Federation
- Policies
- Demo flow

