# Module 6 - Federated Endpoints configurarion

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


---

[:arrow_right: Module 7 - Deploy the demostration application](/modules/module-07-application.md)   <br>

[:arrow_left:  Module 5 - Redis installation and configuration](/modules/module-05-redis.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)