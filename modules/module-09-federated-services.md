# Module 9 - Federated Services configuration

First we need to label the testdb service in all our clusters so that the Tigera controller can federate them. Do this in each of your clusters:

```bash
kubectl label svc -n redis testdb federation=yes
```

Now apply the federated svc yaml

```bash
kubectl apply -f federation-setup/testdb-federated.yaml
```

Now you want to check that the endpoints in out new federated testdb svc has the remote cluster endpoints

On each cluster, do this

```bash
kubectl get endpoints -n redis testdb-federated -oyaml
```

You should see something like this:

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  annotations:
    federation.tigera.io/serviceSelector: federation == "yes"
  creationTimestamp: "2023-03-02T00:26:17Z"
  name: testdb-federated
  namespace: redis
  resourceVersion: "1240287"
  uid: d4e1ec9e-519d-415f-9f1e-2598698d1f42
subsets:
- addresses:
  - ip: 10.0.0.166
    nodeName: aks-nodepool1-62893527-vmss000004
    targetRef:
      kind: Pod
      name: demo-clustera-2
      namespace: redis
      resourceVersion: "1240277"
      uid: c5e7139e-f3a2-45f8-9296-e43d7ad78ffd
  ports:
  - name: redis
    port: 11069
    protocol: TCP
- addresses:
  - ip: 10.1.1.3
    nodeName: aks-nodepool1-86764462-vmss000005
    targetRef:
      kind: Pod
      name: calico-demo-remote-canadacentral/demo-clusterb-1
      namespace: redis
      resourceVersion: "908315"
      uid: e7d5f978-4031-4d2b-afaa-d4721023001f
  ports:
  - name: redis
    port: 11069
    protocol: TCP
```
Note the nodeName fields as well as ```. targetRef.name``` field referencing the remote cluster. Also compare the pod names and IP addresses which will give the full picture.

We're not done yet, our hipstershop is still broken because we purposely haven't pointed to the federated svc that we called ```testdb-federated```

Check the service:

```bash
kubectl get svc -n redis | grep testdb                    
testdb               ClusterIP   10.0.25.56    <none>        11069/TCP           2d12h
testdb-federated     ClusterIP   10.0.27.165   <none>        11069/TCP           8h
testdb-headless      ClusterIP   None          <none>        11069/TCP           2d12h
```

Now let's edit the deployment for the cartservice to point to the federated svc

```bash
kubectl edit deploy cartservice -n hipstershop
```

Look for the line REDIS_ADDR and change the value to ```testdb-federated.redis``` :

```bash
- name: REDIS_ADDR
  value: testdb-federated.redis:11069
```

>**Note:** "There's a better way to do this with kubectl patch than editing the deployment but I'm too lazy to do it now. We fix this in post - KB"

You'll see the cartservice pod get recreated and once it's up refresh your browser page and the app should reload because now it's essentially talking to the replicated db in your working cluster/s. Yay.


---

[:arrow_right: Module 10 - Clean up](/modules/module-10-clean-up)    <br>

[:arrow_left:  Module 8 - Creating a failure scenario](/modules/module-08-failure-scenario.md) 
[:leftwards_arrow_with_hook: Back to Main](/README.md)