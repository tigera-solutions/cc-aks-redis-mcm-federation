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

6. Test the admisson controller on each cluster by trying to create an invalid specification. 

   ```bash
   bash redis/webhook/test-ac.sh
   ```

   You should get a result that says something like this:

   <pre>
   Error from server: error when creating "STDIN": admission webhook "redb.admission.redislabs" denied the request: 'illegal' is an invalid value for 'eviction_policy'
   </pre>

   This message means that the admission controller is not allowing an invalid configuration to be applied, verifying that it works.

>**Reference**: https://docs.redis.com/latest/kubernetes/deployment/quick-start/


## Creating the active-active Redis databases

Creating an active-active database requires routing network access between two Redis Enterprise clusters residing in different Kubernetes clusters. Without the proper access configured for each cluster, syncing between the databases instances will fail.

### Setting up Azure Private DNS Zone and records

1. First you need to setup your DNS aliases in Azure Private DNS for each cluster.  

   Create a new Private DNS zone and then, create the DNS A records in there. 

   ![zone](/redis/images/private_zones.png)

   ![names](/redis/images/dns_names.png)

2. The next step is to ensure is that you have added the required Vnets of all the clusters the DNS zone to the virtual network links page so that the cluster vnets can actually resolve your DNS names in the zone.

   ![vnet_links](/redis/images/vnet_links.png)

   Before moving forward, make sure that the `Link status` is `Completed`.

### Getting the active-active config parameters ready

1. Run the script to create the active-active configuration.

   ```bash
   bash redis/create-db.sh
   ```

   - If it all went well then status should go from `started` -> `finished`

     <pre>
     Task c28d64db-c652-4530-afa0-d539d001f28f created
     ---> CRDB GUID Assigned: crdb:b787a586-c212-4de5-93cd-aff32190a972
     ---> Status changed: queued -> started
     ---> Status changed: started -> finished
     </pre>

   - Check that services got created for your db (testdb in this example) on both clusters.

     ```bash
     kubectl get svc -n redis
     ```

   The output should show the following:

   <pre>
   NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)             AGE
   admission            ClusterIP   10.1.27.12    <none>        443/TCP             20d
   demo-clustera        ClusterIP   10.1.25.127   <none>        9443/TCP,8001/TCP   20d
   demo-clustera-prom   ClusterIP   None          <none>        8070/TCP            20d
   demo-clustera-ui     ClusterIP   10.1.25.183   <none>        8443/TCP            20d
   testdb               ClusterIP   10.1.27.18    <none>        11069/TCP           7m32s
   testdb-headless      ClusterIP   None          <none>        11069/TCP           7m32s
   </pre>


### Testing that replication works

- Change context to your first cluster and bash into one of the db pods 

  ```bash
  kubectl exec -it -n redis demo-clustera-0 -- /bin/bash
  ```

- Connect to db ClusterIP service for your cluster 

  ```bash
  root@demo-clustera-0:/data# redis-cli -h testdb -p 11069
  testdb:11069>
  testdb:11069> set Name "Calico"
  OK
  testdb:11069> set State "Tigera"
  OK
  ```

- Change context to your second cluster and bash into one of the db pods

- When you get the Keys you created, you should see the values got replicated to this cluster's db 

  ```bash
  root@demo-clusterb-0:/data# redis-cli -h testdb -p 11069
  testdb:11069> get Name
  "Calico"
  testdb:11069> get State
  "Tigera"
  ```

>**Reference**: https://docs.redis.com/latest/kubernetes/re-clusters/create-aa-database/

---

[:arrow_right: Module 6 - Federated Endpoints configurarion](/modules/module-06-federated-endpoints.md)  <br>

[:arrow_left:  Module 4 - Deploy and configure HAProxy Ingress](/modules/module-04-haproxy-ingress.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)
