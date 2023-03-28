# Module 8 - Creating a failure scenario

Let's break the db service by putting the Redis pods in 'recovery' mode. In this mode the pods all get recreated, but the database will be offline because there is no quorum (all 3 pods went down). 

While in one cluster, Redis+K8s can survive 2/3 pods dying - however, all 3 pods dying or the database getting degraded by losing quorum is a situation that can make the db in one cluster/region fail by complete loss of quorum. In this scenario, while the pod endpoint IP is still reachable but database service times out, there is still a snapshot of the db that can be used to repair it but human intervention is necessary.

We will utilize this failure scenario to take down the database and demo the power of Calico Cloud federated services with Redis in Active-Active replication across 2 (or more) clusters and how to survive this situation without much service loss.

Pick one cluster (or more) to take down the service and change to that context, just remember that atleast one cluster should have it's redis and testdb svc working properly: 

First let's put the Redis pods in 'recovery' state in the clusters you want to take down:

```bash
kubectl -n redis patch rec demo-clustera --type merge --patch '{"spec":{"clusterRecovery":true}}'
```

The STATE for the CRD rec should go into ```Recoveringxxx``` mode and you should see the pods recreating one by one as per the StatefulSet

```bash
kubectl get rec -n redis
NAME            NODES   VERSION     STATE                SPEC STATUS   LICENSE STATE   SHARDS LIMIT   LICENSE EXPIRATION DATE   AGE
demo-clustera   3       6.2.18-65   RecoveringFirstPod   Valid                                                                  2d12h
```

```bash
kubectl get pods -n redis
NAME                                             READY   STATUS    RESTARTS   AGE
demo-clustera-0                                  2/2     Running   0          2m19s
demo-clustera-1                                  1/2     Running   0          57s
```

Now while this is going on, refresh your browser page and it should timeout with Error 500 that the Redis service is not reachable or an Error 504 Gateway Not Available

![fail](app/images/fail.png)

![fail500](app/images/fail500.png)

We want to now use a federated service for testdb to ensure HA and bring up the svc again.


---

[:arrow_right: Module 9 - Federated Services configuration](/modules/module-09-federated-services.md)  <br>

[:arrow_left:  Module 7 - Deploy the demostration application](/modules/module-07-application.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)