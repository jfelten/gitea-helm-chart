# Gitea Helm chart
[Gitea](https://gitea.com/) is a lightweight github clone.  This is for those who wish to self host theri own git repos on kubernetes.

## Introduction

This is a kubernetes helm chart for [Gitea](https://gitea.com/) a lightweight github clone.  It deploys a pod containing containers for the Gitea application along with a Postgresql db for storing application state. It can create peristent volume claims if desired, and also an ingress if the kubernetes cluster supports it.

This chart was developed and tested on kubernetes version 1.10, but should work on earlier or later versions.

## Prerequisites
 
- A kubernetes cluster ( most recent release recommended)
- helm client and tiller installed on the cluster
- Please ensure that nodepools have enough resources to run both a web application and database

## Installing the Chart

To install the chart with the release name `gitea` in the namespace `tools` with the customized values in custom_values.yaml run:

```bash
$ helm install -- values custom_values.yaml --name gitea --namespace gittea jfelten/gitea
```
or locally:

```bash
$ helm install --name gitea --namewspace tools .
```
> **Tip**: You can use the default [values.yaml](values.yaml)
> 
### Example custom_values.yaml configs

This configuration creates pvcs with the storageclass glusterfs that cannot be deleted by helm, a kubernetes nginx ingress that serves the web applcation on external dns name git.example.com:8880 and exposes ssh through a NodePort that is exposed externally on a router using port 8022. The external DNS name for ssh is git.example.com.

```yaml
ingress: 
  enabled: true
  useSSL: false
  ## annotations used by the ingress - ex for k8s nginx ingress controller:
  ingress_annotations: 
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - lab2"

service:
  http:
    serviceType: ClusterIP
    port: 3000
    externalPort: 8280
    externalHost: git.example.com
  ssh:
    serviceType: NodePort
    port: 22
    nodePort: 30222
    externalPort: 8022
    externalHost: git.example.com
     
persistence:
  enabled: true
  giteaSize: 10Gi
  postgresSize: 5Gi
  storageClass: glusterfs
  accessMode: ReadWriteMany
  annotations:
    "helm.sh/resource-policy": keep
```


## Uninstalling the Chart

To uninstall/delete the `gitea` deployment:

```bash
$ helm delete gitea --purge
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Data Management

This chart will use and create optional persistent volume claims for both postgres and gitea data.  By default the data will be deleted upon uninstalling the chart. This is not ideal but can be managed in a couple ways:

* prevent helm from deleting the pvcs it creates.  Do this by enabling annotation: helm.sh/resource-policy": keep in the pvc optional annotations 

```yaml
persistence:
  annotations:
    "helm.sh/resource-policy": keep
```
* create a pvc outside the chart and configure the chart to use it.  Do this by setting the persistence existingGiteaClaim and existingPostgresClaim properties.

```yaml
 existingGiteaClaim: gitea-gitea
 existingPostgresClaim: gitea-postgres
```
a trick that can be is used to first set the helm.sh/resource-policy annotation so that the chart generates the pvcs, but doesn't delete them.  Upon next deplyment set the exsiting claim names to the generated values.

## Ingress And External Host/Ports

Gitea requires ports to be exposed for both web and ssh traffic.  The chart is flexible and allow a combination of either ingresses, loadblancer, or nodeport services.

To expose the web application this chart will generate an ingress using the ingress controller of choice if specified. If an ingress is enabled services.http.externalHost must be specified. To expose SSH services it relies on either a LoadBalancer or NodePort.

## Configuration

Refer to [values.yaml](values.yaml) for the full run-down on defaults.

