# Module 4 - Deploy and configure HAProxy Ingress

For configuring multi-cluster redundancy for Redis, a ingress controller is needed.
The HA proxy will be installed to perform this task.

1. Copy the setup example environment variables file `setup.env.example` to `setup.env`. 

   ```bash
   cp haproxy-ingress/setup.env.example haproxy-ingress/setup.env
   ```

2. Edit the `setup.env` file and configure the name of the kubeconfig contexts of the both clusters in it following the format from from the `setup.env.example` file.

   ```bash
   vi haproxy-ingress/setup.env
   ```

3. Run the script to have the HA ingress configured for Redis.

   ```bash
   bash haproxy-ingress/install.sh
   ```

4. An internal Azure loadbalancer will be created. The traffic will be ingressed using the EXTERNAL-IP IP address and redirected to the Redis database. You can verify its configuration using the command below:

   ```bash
   kubectl get svc -n ingress-controller
   ```
   You should see an output like:

   <pre>
   NAME                      TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
   ingress-haproxy-ingress   LoadBalancer   10.1.27.85   10.1.1.75     80:30591/TCP,443:30063/TCP   23h
   </pre>

---

[:arrow_right: Module 5 - Redis installation and configuration](/modules/module-05-redis.md)  <br>

[:arrow_left:  Module 3 - Connect your AKS cluster to Calico Cloud](/modules/module-03-connect-calicocloud.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)