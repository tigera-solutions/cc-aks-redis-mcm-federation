# Module 5 - Redis installation and configuration

The install bash script assumes you have the context names for each kubeconfig file and they're setup to be unique (AKS does this already and merges them properly)

1. Copy the example environment variables file 

   ```bash
   cp redis/setup.env.example redis/setup.env
   ```

2. In the file `redis/setup.env` you need to setup the name of the kubeconfig contexts of the both clusters in it following the format from from the `redis/setup.env.example` file. There are also variable that will be used for setting up the cluster. Don't change them, unless you know what you are doing.
 
   ```bash
   vi redis/setup.env
   ```

3. Run the script at  `redis/install-rec.sh`
  
   ```bash
   bash redis/install-rec.sh
   ```


4. Check de status for the Redis Entreprise Cluster (rec CRD) on both clusters using the following command, changing the context.

  ```bash
  kubectl get -n redis rec                                                       
  ```

   The `STATE` should be `Running` and `SPEC STATUS` should be `Valid` (will take a while to deploy the StatefulSets)

   <pre>
   NAME            NODES   VERSION     STATE     SPEC STATUS   LICENSE STATE   SHARDS LIMIT   LICENSE EXPIRATION DATE   AGE
   demo-clusterb   3       6.2.18-65   Running   Valid         Valid           4              2023-03-19T20:36:00Z      3h32m
   </pre>


5. Install the REC admission controller by running the script on each cluster.  

   ```bash
   bash redis/webhook/install-ac.sh
   ```

6. Test the admisson controller on each cluster by trying to create an invalid spec

   ```bash
   bash redis/webhook/test-ac.sh
   ```

   You should get a result that says something like this

   <pre>
   Error from server: error when creating "STDIN": admission webhook "redb.admission.redislabs" denied the request: 'illegal' is an invalid value for 'eviction_policy'
   </pre>


>**Reference**: https://docs.redis.com/latest/kubernetes/deployment/quick-start/


## Creating the active-active Redis databases

Creating an Active-Active database requires routing network access between two Redis Enterprise clusters residing in different Kubernetes clusters. Without the proper access configured for each cluster, syncing between the databases instances will fail.

This process consists of:

1. Documenting values to be used in later steps. It’s important these values are correct and consistent.
2. Editing the Redis Enterprise cluster (REC) spec file to include the ActiveActive section. This will be slightly different depending on the K8s distribution you are using.
3. Creating the database with the crdb-cli command. These values must match up with values in the REC resource spec.

### Setting up Azure Private DNS Zone and records

1. First you need to setup your DNS aliases in Azure Private DNS for each cluster.  

   There is already an RG and zone setup for this in Azure, feel free to create the DNS A records in there and use the same zone if you want. 

   ![zone](/redis/images/private_zones.png)

   ![names](/redis/images/dns_names.png)

2. The next step is to ensure is that you have added the required Vnets of all the clusters the DNS zone to the virtual network links page so that the cluster vnets can actually resolve your DNS names in the zone.

   ![vnet_links](/redis/images/vnet_links.png)


### Getting the active-active config parameters ready

1. Create a copy the example active config file.

   ```bash
   cp redis/activeconfig.txt.example redis/activeconfig.txt
   ``` 

2. Open up the file `redis/activeconfig.txt` in your text editor.

   ```bash
   vi redis/activeconfig.txt
   ```

3. Get password: 

   Setup the context variables for each of the context names 
   ```bash
   export CONTEXT_NAME1=
   export CONTEXT_NAME2=
   ```
   


   ```bash
   k config use-context $CONTEXT_NAME1
   export SECRET1=$(k get secret -n redis demo-clustera -o jsonpath='{.data.password}' | base64 --decode)
   k config use-context $CONTEXT_NAME2
   export SECRET2=$(k get secret -n redis demo-clusterb -o jsonpath='{.data.password}' | base64 --decode)
   ```

   


crdb-cli crdb create \
  --name testdb \
  --memory-size 500MB \
  --encryption yes \
  --port 11069 \
  --instance fqdn=demo-clustera.redis.svc.cluster.local,url=https://api-clustera.tigera.redisdemo.com,username=demo@redislabs.com,password=XWHuHKvh,replication_endpoint=testdb-clustera.tigera.redisdemo.com:443,replication_tls_sni=testdb-clustera.tigera.redisdemo.com \
  --instance fqdn=demo-clusterb.redis.svc.cluster.local,url=https://api-clusterb.tigera.redisdemo.com,username=demo@redislabs.com,password=u1OQ1LH8,replication_endpoint=testdb-clusterb.tigera.redisdemo.com:443,replication_tls_sni=testdb-clusterb.tigera.redisdemo.com


crdb-cli crdb create \
  --name testdb \
  --memory-size 500MB \
  --encryption yes \
  --port 11069 \
  --instance fqdn=demo-clustera.redis.svc.cluster.local,url=https://api-clustera.tigera.redisdemo.com,username=demo@redislabs.com,password=XWHuHKvh,replication_endpoint=testdb-clustera.tigera.redisdemo.com:443,replication_tls_sni=testdb-clustera.tigera.redisdemo.com \
  --instance fqdn=demo-clusterb.redis.svc.cluster.local,url=https://api-clusterb.tigera.redisdemo.com,username=demo@redislabs.com,password=u1OQ1LH8,replication_endpoint=testdb-clusterb.tigera.redisdemo.com:443,replication_tls_sni=testdb-clusterb.tigera.redisdemo.com






3. Get the values for the two clusters using the reference link as an example.

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

>**Reference**: https://docs.redis.com/latest/kubernetes/re-clusters/create-aa-database/

---

[:arrow_right: Module 6 - Federated Endpoints configurarion](/modules/module-06-federated-endpoints.md)  <br>

[:arrow_left:  Module 4 - Deploy and configure HAProxy Ingress](/modules/module-04-haproxy-ingress.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)
