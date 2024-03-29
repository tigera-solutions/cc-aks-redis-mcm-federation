> :warning: **This repo is purely a work-in-progress(WIP) and is in active development. Other than contributors, anyone else should probably not try the stuff in this repo and expect it to work as is until it's finished and ready!**

# AKS cluster-mesh for Redis DB using Calico Cloud

## Welcome

In this AKS-focused workshop, you will learn how to implement Calico Cloud multi-cluster manangement and federation feature to achieve high availability for Redis database across multiple clusters. 

Calico Cloud federated endpoint identity and federated services are implemented in Kubernetes at the network layer. To apply fine-grained network policy between multiple clusters, the pod source and destination IPs must be preserved. So these features are valuable only if your clusters are designed with common networking across clusters with no encapsulation

Federated services works with federated endpoint identity, providing cross-cluster service discovery for a local cluster. Federated services use the Tigera Federated Services Controller to federate all Kubernetes endpoints (workload and host endpoints) across all of the clusters. The Federated Services Controller accesses service and endpoints data in the remote clusters directly through the Kubernetes API.

You will come away from this workshop with an understanding of how you can create a cluster-mesh to support high availability of applications running across multiple clusters, along with best practices you can implement in your organization.

### Time Requirements

The estimated time to complete this workshop is 75-120 minutes.

### Target Audience

- Cloud Professionals
- DevSecOps Professional
- Site Reliability Engineers (SRE)
- Solutions Architects
- Anyone interested in Calico Cloud :)

### Learning Objectives

1. Learn how to configure Calico Cloud federated endpoints across clusters.
2. Create federated services to provide high availability for your applicacion using multiple clusters.

## Modules

This workshop is organized in sequential modules. One module will build up on top of the previous module, so please, follow the order as proposed below.
 
Module 1 - [Getting Started](/modules/module-01-getting-started.md)  
Module 2 - [Create the Azure Resources](/modules/module-02-create-resources.md)  
Module 3 - [Connect the Azure AKS clusters to Calico Cloud](/modules/module-03-connect-calicocloud.md)  
Module 4 - [Deploy and configure HAProxy Ingress](/modules/module-04-haproxy-ingress.md)  
Module 5 - [Redis installation and configuration](/modules/module-05-redis.md)  
Module 5.a - [Recovering Redis after an outage](/modules/module-05a-redis-recovery.md)  
Module 6 - [Federated Endpoints configurarion](/modules/module-06-federated-endpoints.md)  
Module 7 - [Deploy the demostration application](/modules/module-07-application.md)  
Module 8 - [Creating a failure scenario](/modules/module-08-failure-scenario.md)  
Module 9 - [Federated Services configuration](/modules/module-09-federated-services.md)  
Module 10 - [Clean up](/modules/module-10-clean-up)  

[Change Log - To Do List](/ChangeLog-ToDo.md)

--- 

### Useful links

- [Project Calico](https://www.tigera.io/project-calico/)
- [Calico Academy - Get Calico Certified!](https://academy.tigera.io/)
- [O’REILLY EBOOK: Kubernetes security and observability](https://www.tigera.io/lp/kubernetes-security-and-observability-ebook)
- [Calico Users - Slack](https://slack.projectcalico.org/)

**Follow us on social media**

- [LinkedIn](https://www.linkedin.com/company/tigera/)
- [Twitter](https://twitter.com/tigeraio)
- [YouTube](https://www.youtube.com/channel/UC8uN3yhpeBeerGNwDiQbcgw/)
- [Slack](https://calicousers.slack.com/)
- [Github](https://github.com/tigera-solutions/)
- [Discuss](https://discuss.projectcalico.tigera.io/)

> **Note**: The examples and sample code provided in this workshop are intended to be consumed as instructional content. These will help you understand how Calico Cloud can be configured to build a functional solution. These examples are not intended for use in production environments.