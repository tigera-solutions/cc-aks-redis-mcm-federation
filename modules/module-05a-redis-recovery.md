### Redis service and database recovery

- When you stop and start an AKS cluster or as you go through the rest of the steps, there are two things that need to be done whenever the Redis pods are ALL taken down in a cluster and brought back up
  1. The Redis API service and pods need to be recovered as there is total loss of quorum (all 3 pods went down when the cluster was stopped)
  2. Any database (testdb in our case) also needs to be recovered.

- Both of these steps are to be done in sequence in one of the redis pods: 
  1. First run the cluster recovery command for your REC

     ```bash
     kubectl -n redis patch rec demo-clustera --type merge --patch '{"spec":{"clusterRecovery":true}}'
     ```

      Wait for all the pods in the StatefulSet to come back up fully
      All 3 pods should show ```2/2``` running containers

      ```bash
      NAME                                          READY   STATUS    RESTARTS       AGE
      demo-clusterb-0                               2/2     Running   0              120m
      demo-clusterb-1                               2/2     Running   0              119m
      demo-clusterb-2                               2/2     Running   0              116m
      ```

  2. Open a shell to one of the redis pods in your cluster (in this example clustera):

      ```bash
      kubectl exec -it demo-clustera-0 -n redis -- /bin/bash
      ```

      Check that the database is in a recoverable state

      ```bash
      rladmin status databases
      ```

      The output should show in ```STATUS``` as ```recovery (ready)```

      ```bash
      redislabs@demo-clustera-0:/opt$ rladmin status databases
      DATABASES:
      DB:ID         NAME       TYPE     STATUS                     SHARDS     PLACEMENT       REPLICATION        PERSISTENCE        ENDPOINT
      db:2          testdb     redis    recovery (ready)           1          dense           enabled            disabled           redis-11069.demo-clustera.redis.svc.cluster.local:11069
      ```

      Now run the command to recover the database

      ```bash
      rladmin recover all
      ```

      The database recovery should complete 100% fully

      ```bash
        0% [ 0 recovered | 0 failed ] |                                    | Elapsed Time: 0:00:00[testdb (db:2) recovery] Initiated.
        50% [ 0 recovered | 0 failed ] |################################   | Elapsed Time: 0:00:00[testdb (db:2) recovery] Completed successfully
        100% [ 1 recovered | 0 failed ] |##################################| Elapsed Time: 0:00:02
      ```

      Check the status of database, ```STATUS``` should show ```active```

      ```bash
      DATABASES:
      DB:ID          NAME        TYPE      STATUS      SHARDS      PLACEMENT        REPLICATION         PERSISTENCE         ENDPOINT
      db:2           testdb      redis     active      1           dense            enabled             disabled            redis-11069.demo-clustera.redis.svc.cluster.local:11069