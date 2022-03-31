#!/bin/bash

if [[ $(hostname -s) = k8s-master* ]]; then

  	## Prepare exercises
	sudo dos2unix /vagrant/resources/q/* > /dev/null 2>&1
	sudo dos2unix /vagrant/resources/a/* > /dev/null 2>&1
	sudo chmod +x /vagrant/resources/q/*
	sudo cp /vagrant/resources/q/*  /usr/local/bin/
	
	## Install etcd-client
	curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4  | wget -qi -
	tar -xvf etcd*.tar.gz
	sudo mv etcd-v*-linux-amd64/etcdctl /usr/local/bin/
	rm -rf etcd-*

	## Install jq
	sudo yum install epel-release -y
	sudo yum update -y
	sudo yum install httpd-tools jq git -y
	
	## Init Kubernetes
	echo "kubeadm init --apiserver-advertise-address $1 --pod-network-cidr=$2"
	kubeadm init --apiserver-advertise-address $1 --pod-network-cidr=$2

  	## Transfer keys to workers. With this key it can access master passwordless with vagrant user
	su - vagrant -c "cp /vagrant/scripts/id_rsa /home/vagrant/.ssh/"
	su - vagrant -c "cp /vagrant/scripts/id_rsa.pub /home/vagrant/.ssh/"
	chmod 400 /home/vagrant/.ssh/*

 	## Set cluster configuration
	mkdir -p /home/vagrant/.kube
	sudo cp -Rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config
	sudo chown -R vagrant:vagrant /home/vagrant/.kube/
	## Enable service
	sudo systemctl enable kubelet

	## Install cni networking
	#su vagrant -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
	su vagrant -c "kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')\""
	## Config auto-completion
	su vagrant -c "echo \"source <(kubectl completion bash)\" >> ~/.bashrc"

	## Copy certificates so we are able to access etcd server
	sudo cp -r /etc/kubernetes/pki/etcd/ /home/vagrant/
	sudo chown -R vagrant ./etcd/

	## namespace for apps
	su vagrant -c "kubectl create ns kube-dashboard-ingress"
 	su vagrant -c "kubectl create ns app"

  	## Create joining token for workers
	kubeadm token create --print-join-command --ttl 0 > /tmp/master-join-command.sh
	sudo chown vagrant /tmp/master-join-command.sh

fi