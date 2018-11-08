# Gitea Helm chart
[Gitea](https://gitea.com/) is a lightweight github clone.  This is for those who wish to self host their own git repos on kubernetes.

## Introduction

This chart creates a pod consisting of [gitea](https://gitea.com/), postgres and memcached containers.  Each pod performs the role of application, data persistence, and cache. All containers are rolled into a single pod vs using dependent charts for ease of maintenance, easier packaging, and simplicity.  Neither postgres nor memcache is exposed as a service and only usable within the gitea pod.

The chart can create persistent volume claims if desired cluster supports it. The chart can also mount storage directly and can be used without a storage class.  An ingress can be created provided an ingress controller is installed on the cluster.

This chart was developed and tested on kubernetes version 1.12, but should work on earlier or later versions.

## Prerequisites

- A kubernetes cluster ( most recent release recommended)
- helm client and tiller installed on the cluster
- Please ensure that nodepools have enough resources to run both a web application and database

## Installing the Chart

To install the chart with the release name `gitea` in the namespace `tools` with the customized values in custom_values.yaml run:

```bash
helm repo add jfelten https://jfelten.github.io/helm-charts/charts
helm install jfelten/gitea

# or for a more custom install
$ helm install --values custom_values.yaml --name gitea --namespace tools jfelten/gitea
```
or to clone locally and install:
```bash
git clone https://github.com/jfelten/gitea-helm-chart.git
cd gitea-helm-chart
$ helm install --name gitea --namespace tools .
```
> **Tip**: You can use the default [values.yaml](values.yaml)
>
### Example custom_values.yaml configs

This configuration creates pvcs with the storageclass glusterfs that cannot be deleted by helm, a kubernetes nginx ingress that serves the web application on external dns name git.example.com:8880 and exposes ssh through a NodePort that is exposed externally on a router using port 8022. The external DNS name for ssh is git.example.com.

```yaml
ingress:
  enabled: true
  ## annotations used by the ingress - ex for k8s nginx ingress controller:
  ingress_annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - my git"
  tls:
    - secretName: <TLS_SECRET>
      hosts:
        - 'git.example.com'

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

The main deployment contains 2 containers: one for gitea and one for postgres.  Both of these have separate storage requirements and the chart needs 2 sources of persistent storage: one for git data, and one for postgres data.

This chart is used to host code on a bare metal cluster. It was designed with data stability in mind. The maintainability of dynamic storageclass provisioned storage has been not great, so the ability to mount direct volumes without a storage class was added to simplify and increase robustness.  As a consequence there is a lot flexibility in how persistence can be configured.

#### Default persistence behavior

If no persistence is configured it will use emptyDir storage on the node that gets deleted when the chart is deleted.  If configured
this chart will use and create optional persistent volume claims for both postgres and gitea data.  By default the data will be deleted upon uninstalling the chart. This is not ideal but can be managed in a couple ways:

* prevent helm from deleting the pvcs it creates.  Do this by enabling annotation: helm.sh/resource-policy": keep in the pvc optional annotations

```YAML
persistence:
  annotations:
    "helm.sh/resource-policy": keep
```
* create a pvc outside the chart and configure the chart to use it.  Do this by setting the persistence existingGiteaClaim and existingPostgresClaim properties.

```YAML
persistence:
  enabled: true
  existingGiteaClaim: gitea-gitea
  existingPostgresClaim: gitea-postgres
```

* use the direct volume mount capabilities of this chart.  The directGiteaVolumeMount and directPostgresVolumeMount values will override volume configuration in the main pod deployment.  The values need to be valid yaml per the kubernetes deployment volume api spec. No storageclass needed!

```YAML
persistence:
  enabled: true
  directGiteaVolumeMount: |-
    glusterfs:
      endpoints: glusterfs
      path: gitea
  directPostgresVolumeMount: |-
    glusterfs:
      endpoints: glusterfs
      path: gitea_db
```
a trick that can be is used to first set the helm.sh/resource-policy annotation so that the chart generates the pvcs, but doesn't delete them.  Upon next deployment set the existing claim names to the generated values.

## Ingress And External Host/Ports

Gitea requires ports to be exposed for both web and ssh traffic.  The chart is flexible and allow a combination of either ingresses, loadbalancer, or nodeport services.

To expose the web application this chart will generate an ingress using the ingress controller of choice if specified. If an ingress is enabled services.http.externalHost must be specified. To expose SSH services it relies on either a LoadBalancer or NodePort.

## Configuration

Refer to [values.yaml](values.yaml) for the full run-down on defaults.

The following table lists the configurable parameters of this chart and their default values.

| Parameter                  | Description                                     | Default                                                    |
| -----------------------    | ---------------------------------------------   | ---------------------------------------------------------- |
| `images.gitea`                    | `gitea` image                     | `gitea/gitea:1.6`                                                 |
| `images.postgres`                 | `postgres` image                            | `postgres:9.6.2`                                                    |
| `images.imagePullPolicy`          | Image pull policy                               | `Always` if `imageTag` is `latest`, else `IfNotPresent`    |
| `images.imagePullSecrets`         | Image pull secrets                              | `nil`                                                      |
| `memcached.maxItemMemory`             | memcached maxItemMemory parameter                 | `64`                                                 |
| `memcached.verbosity`             | memcached logging verbosity parameter                 | `v`                                                 |
`memcached.extendedOptions`             | memcached extendedOptions parameter                 | `modern`                                                 |
| `ingress.enable`             | Switch to create ingress for this chart deployment                 | `false`                                                 |
| `ingress.tls`         | The presence of this value changes default git protocol from http to https and configures tls secret and host name - see values.yaml example       | `nil`                                       |
| `ingress.ingress_annotations`          | annotations used by the ingress | `nil`                                                    |
| `service.http.serviceType`         | type of kubernetes services used for http i.e. ClusterIP, NodePort or LoadBalancer                | `ClusterIP`                                                 |
| `service.http.port`       | http port for web traffic                               | `3000`                                                      |
| `service.http.NodePort`            |  Manual NodePort for web traffic                 | `nil`                                                      |
| `service.http.externalPort`           | Port exposed on the internet by a load balancer or firewall that redirects to the ingress or NodePort        | `nil`                                                      |
| `service.http.externalHost`           | IP or DNS name exposed on the internet by a load balancer or firewall that redirects to the ingress or Node for http traffic                       | `nil`                                                      |
| `service.ssh.serviceType`         | type of kubernetes services used for ssh i.e. ClusterIP, NodePort or LoadBalancer                | `ClusterIP`                                                 |
| `service.ssh.port`       | http port for web traffic                               | `22`                                                      |
| `service.ssh.NodePort`            |  Manual NodePort for ssh traffic                 | `nil`                                                      |
| `service.ssh.externalPort`           | Port exposed on the internet by a load balancer or firewall that redirects to the ingress or NodePort        | `nil`                                                      |
| `service.ssh.externalHost`           | IP or DNS name exposed on the internet by a load balancer or firewall that redirects to the ingress or Node for http traffic                                                      |
| `resources.gitea.requests.memory`         | gitea container memory request                             | `100Mi`                                                      |
| `resources.gitea.requests.cpu`      | gitea container request cpu          | `500m`                                            |
| `resources.gitea.limits.memory`    | gitea container memory limits                      | `2Gi`                          |
| `resources.gitea.limits.cpu`                | gitea container CPU/Memory resource requests/limits             | Memory: `1`                               |
| `resources.postgres.requests.memory`         | postgres container memory request                             | `256Mi`                                                      |
| `resources.postgres.requests.cpu`      | gitea container request cpu          | `100m`                                            |
| `persistence.enabled`        | Create PVCs to store gitea and postgres data?                | `false`                               |
| `peristence.existingGiteaClaim`    | Already existing PVC that should be used for gitea data.                       | `nil`                                                      |
| `peristence.existingPostgresClaim`      |Already existing PVC that should be used for postgres data.                      | `nil`
| `peristence.directGiteaVolumeMount`      |Yaml used to mount a volume for git storage directly without pvcs                           | `nil`
| `peristence.directPostgresVolumeMount`      |Yaml used to mount a volume for git storage directly without pvcs                           | `nil`                                                  |                                                  |
| `persistence.giteaSize`             | Size of gitea pvc to create                                        | `10Gi`                                                     |
| `persistence.postgresSize`             | Size of postgres pvc to create | `5Gi`                                                |
| `persistence.storageClass`         | NStorageClass to use for dynamic provision if not 'default'    | `nil`                                                      |
| `persistence.annotations`    | Annotations to set on created PVCs                           | `nil`                                                    |
| `postgres.secret` | Generated Secret to store postgres passwords   | `postgressecrets`                                                     |
| `postgres.subPath`             | Subpath for Postgres data storage                  | `nil`                                                         |
| `postgres.dataMountPath`             | Path for Postgres data storage                  | `nil`                                                         |
| `affinity`                 | Affinity settings for pod assignment            | {}                                                         |
| `tolerations`              | Toleration labels for pod assignment            | []
| `config.secretKey` | gitea config SECRET_KEY | set to a random password
| `config.disableInstaller` | gitea config INSTALL_LOCK, do not require manual install step | `false`

## Performance

We have observed that gitea performance is heavily file system dependent. If high performance is required be sure to use fast storage. Otherwise tune container resource settings to suit your needs.

## Initial install configuration

With default configuration gitea will require first user to complete `install` procedure.
In order to skip this step after installation, set config.disableInstaller to true

```yaml
config:
  disableInstaller: true
```
