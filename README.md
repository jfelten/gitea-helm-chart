# Gitea Helm chart
[Gitea](https://gitea.com/) is an application to code, test, and deploy code together.

## Introduction

This is a kubernetes helm chart for [Gitea](https://gitea.com/) a lightweight github clone.  It deploys a pod containing contianrs for the Gitea application along with a Postgresql db for storing application state.

## Prerequisites

- This chart was developed and tested on kubernetes version 1.10, but should work on earlier or later versions
- Please ensure that nodepools have enough resources to run both a web application and database

## Installing the Chart

To install the chart with the release name `gitea` in the namespace `tools` run:

```bash
$ helm install --name gitea --namespace gittea jfelten/gitea
```
or locally:

```bash
$ helm install --name gitea --namewspace tools .
```

## Uninstalling the Chart

To uninstall/delete the `gitea` deployment:

```bash
$ helm delete gitea
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and Gitea-related directives.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install --name my-release incubator/gitea --set 
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install --name my-release -f values.yaml jfelten/gitea
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## Persistence

By default, persistence of Gitea data and configuration happens using PVCs. If you know that you'll need a larger amount of space, make _sure_ to look at the `persistence` section in [values.yaml](values.yaml).

> *"If you disable persistence, the contents of your volume(s) will only last as long as the Pod does. Upgrading or changing certain settings may lead to data loss without persistence."*
