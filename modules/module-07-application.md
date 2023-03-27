# Module 7 - Deploy the demostration application

Let's install the hipstershop microservices app from this repo into all of our clusters. 

- Copy the example env variables file ```cp app/setup.env.example app/setup.env```
- Setup the variables in your ```app/setup.env```
- Run the bringup script ```bash app/install-app.sh```


Now let's check that the ```frontend-external``` service got a public-IP we can use to access the app running on that cluster.

The service output might look like:

```bash
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
frontend-external       LoadBalancer   10.0.25.5     45.26.20.15   80:31077/TCP   6h11m
```

Bring up a broswer and access/use the app

![hipstershop](app/images/hipstershop.png)

Setup a ```redis-cli``` client pod for later debugging with the redis db pods, do this in all clusters

```bash
kubectl run redis-cli3 -n redis --image redis:latest --leave-stdin-open
```

Connect to the testdb database on both your clusters and check that the db is getting populated

```bash
kubectl -n redis exec -it redis-cli3 -- /bin/bash
```

Connect to the local db service

```bash
redis-cli -h testdb -p 11069
```

Get all keys 

```bash
keys *
```

You should get something like:

```
testdb:11069> keys *
  1) "04e26cbe-7b69-40d8-90ea-88ae684456f1"
  2) "e4dbcfa8-5b08-4476-af69-8249b8f71792"
  3) "2ba02043-d00f-4850-b5fc-429d77e9a70d"
  4) "7255eb5b-07ab-4aba-bb77-2a0e094e4f33"
  5) "709aaa33-fab0-462d-9f6a-1f057ae8410a"
  6) "9f8593aa-f83a-4250-aaa1-ca69deaa08cd"
  7) "ca0eab31-519a-4358-bdb5-8ca9d213c4da"
  8) "8ce16017-494d-4894-9d87-3fcb197751d6"
  9) "303478b1-e1b9-43d0-a1d3-5533d5293a66"
 1)  "67a96e15-61bc-49c2-b885-168eb8aa6162"
```

"Insert blurb about the Redis architecture somewhere"

Redis Active-Active db architecture: 

- Basically in one cluster there are 3 Redis pods in active-backup where at any point one pod is active/master and other two are storing shards. 
- The 3 pods maintain a quorum and can survive upto 2 pods dying and the shards moving between the 3 pods but in terms of services or endpoints there will always only be one pod that is active for the database 
- As per the example below, ```demo-clustera-2```  is the active/master pod backing the testdb service:

```bash
kubectl get pods -n redis -o wide | grep demo-clustera                         
demo-clustera-0                                  2/2     Running   0          155m   10.0.0.107   aks-nodepool1-62893527-vmss000005   <none>           <none>
demo-clustera-1                                  2/2     Running   0          153m   10.0.1.69    aks-nodepool1-62893527-vmss000003   <none>           <none>
demo-clustera-2                                  2/2     Running   0          150m   10.0.0.116   aks-nodepool1-62893527-vmss000004   <none>           <none>
```

```bash
kubectl get svc -n redis | grep testdb                                   
testdb               ClusterIP   10.0.25.56    <none>        11069/TCP           2d11h
testdb-headless      ClusterIP   None          <none>        11069/TCP           2d11h
```

```bash
kubectl get endpoints testdb -n redis
NAME     ENDPOINTS          AGE
testdb   10.0.0.116:11069   2d11h
```


---

[:arrow_right: Module 8 - Creating a failure scenario](/modules/module-08-failure-scenario.md)  <br>

[:arrow_left:  Module 6 - Federated Endpoints configurarion](/modules/module-06-federated-endpoints.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)