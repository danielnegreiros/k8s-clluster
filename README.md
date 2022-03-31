k8s-cluster
___
- [1. Intro](#1-intro)
- [2. Installation](#2-installation)
- [3. Topics](#3-topics)
- [4. Kubernetes](#4-kubernetes)

___

## 1. Intro

This is an set of scripts to with a single command generate a Kubernetes Cluster ready for testing and playing with. <br />
It doesn't have any commitment to security or production characteristics.

The goal is quickly set-up a k8s cluster on Windows with Vagrant and VirtualBox\
Or on Linux with Vagrant and you can choose between Libvirt or VirtualBox.

With current configuration it creates a cluster with this set-up

| Node | Function | Access 1 | Access 2 |  Memory | vCpu | User | Passwd |
| :---: | :---: | :---: |  :---: | :---: | :---: | :---: | :---: |
| master   | master | 192.168.50.10 |  127.0.0.1:2100 | 2048  | 2 | vagrant | test123 |
| worker01 | worker | 192.168.50.20 |  127.0.0.1:2101 | 1024 | 2 | vagrant | test123 |
| worker02 | worker | 192.168.50.30 |  127.0.0.1:2102 | 1024 | 2 | vagrant | test123 |

This configuration can be easily changed in the scripts and Vagrant configuration file.

The set-up comes with:
- Kubernetes Web UI (Dashboard)
- Helm 3
- Nginx Controller
- Metal LoadBalancer
- Metrics Server
- Container Engine: Docker

## 2. Installation

- Install Vagrant
- Install VirtualBox
- Download or git clone and then start VMs

If Virtual box
` $ cp Vagrantfile-vb Vagrantfile`
If Libvirt
` $ cp Vagrantfile-lb Vagrantfile`

- Start

```
$ vagrant up
```

- [Installation Procedure in details](Presentations/Installation.md)

- To practice with some exercises.

```
$ question1

Question 1: Create a pod named nginx with the nginx image

To Submit type: submit1
To get a hint  type: hint1

$ submit1

Starting...

Pod Found
Image correct
Pod Running
Pod Ready


You can now delete the nginx POD
Congratulations, you got that right!!!
```

- To stop/start Virtual Machines with vagrant

```
$ vagrant halt
$ vagrant up
```


- To clean up and destroy everything

```
$ vagrant destroy -f
```

## 3. Topics

- Under development. Items are constantly being added or updated.
- If you are not familiarized with Docker. Please see at the end of summary the Docker review first.


## 4. Kubernetes

- Main Objects and concepts
    - [POD](Presentations/Kubernetes/01.01.pod.md)
        - [POD Yaml](Presentations/Kubernetes/01.02.extra-yaml.md)
        - [POD Manifest Data](Presentations/Kubernetes/01.03.manifest-data.md)
    - [ReplicaSet](Presentations/Kubernetes/05.Replica-set.md)
    - [Deployment](Presentations/Kubernetes/10.Deployments.md)
    - [DaemonSet](Presentations/Kubernetes/15.Daemon-Set.md)
    - Stateful Set
    - [StaticPods](Presentations/Kubernetes/20.Static-Pod.md)
    - [Labels and Selectors](Presentations/Kubernetes/25.Labels-and-selectors.md)
    - [Namespaces](Presentations/Kubernetes/30.Namespaces.md)
<br />

- Resources
    - [Metrics Server and Resources](Presentations/Kubernetes/35.Metrics-Server-and-Resources.md)
    - [AutoScaling](Presentations/Kubernetes/40.AutoScaling.md)
<br />

- Services
    - [Custer IP](Presentations/Kubernetes/45.Services-Cluster-IP.md)
    - [Node Port](Presentations/Kubernetes/46.Services-Cluster-NodePort.md)
    - [Load Balancer](Presentations/Kubernetes/47.Services-Cluster-LoadBalancer.md)
<br />

- Scheduling
    - [Taints and Tolerations](Presentations/Kubernetes/50.Taints-and-Tolerations.md)
    - [Manual scheduling](Presentations/Kubernetes/55.Manual-Scheduling.md)
    - [Node Selectors](Presentations/Kubernetes/60.Node-Selector.md)
    - [Node Affinity](Presentations/Kubernetes/65.Node-Affinity.md)
<br />


- Configuration
    - Environment Variables
    - ConfigMaps
    - Secrets
    - CRDs
<br />

- Volumes
    - Volumes
    - Persistent Volume
    - Persistent Volume Claim
<br />

- Networking
    - [Ingress](Presentations/Kubernetes/100.Ingress.md)
    - Network Policy
<br />

- LifeCycle and Logs
    - Readiness Probes
    - Liveness Probes
<br />

- Administration and Security
    - Resource Quotas
    - User and Certificates
    - Service Account
    - Role
    - ClusterRole
    - (Cluster)Role Bindings
    - Nodes Maintenance
    - Real use cases
        - [Set up user access for X namespace](Presentations/Kubernetes/160.Set-up-user-access.md)
<br />

- Helm Package Manager
    - [Helm Installation and Basic Usage](Presentations/Kubernetes/500.Helm-Installation.md)
    - [Helm Upgrades and Rollbacks](Presentations/Kubernetes/505.Helm-Chart-upgr-rollback.md)

<br />

- Apps
    - [Private Registry](Presentations/Kubernetes/600-PrivateRegistry.md)
    - [MongoDB](Presentations/Kubernetes/605-MongoDB.md)

<br />

