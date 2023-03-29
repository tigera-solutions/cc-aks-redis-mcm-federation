# Module 4 - Deploy and configure HAProxy Ingress

- Copy the example env variables file  

  ```bash
  cp haproxy-ingress/setup.env.example haproxy-ingress/setup.env
  ```

- Setup the variables in your 

  ```bash
  vi haproxy-ingress/setup.env
  ```

- Run the bringup script 

  ```bash
  bash haproxy-ingress/install.sh
  ```

Check the internal Azure AKS LB assigned the svc an EXTERNAL-IP off the Vnet subnet

  ```bash
  kubectl get svc -n ingress-controller
  ```

---

[:arrow_right: Module 5 - Redis installation and configuration](/modules/module-05-redis.md)  <br>

[:arrow_left:  Module 3 - Connect your AKS cluster to Calico Cloud](/modules/module-03-connect-calicocloud.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)