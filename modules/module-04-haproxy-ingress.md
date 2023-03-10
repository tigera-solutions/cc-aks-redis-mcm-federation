### Deploy HAProxy-Ingress

- Copy the example env variables file ```cp haproxy-ingress/setup.env.example haproxy-ingress/setup.env```
- Setup the variables in your ```haproxy-ingress/setup.env```
- Run the bringup script ```bash haproxy-ingress/install-haproxy.sh```

```bash
bash haproxy-ingress/install.sh
```

Check the internal Azure AKS LB assigned the svc an EXTERNAL-IP off the Vnet subnet

```bash
kubectl get svc -n ingress-controller
```