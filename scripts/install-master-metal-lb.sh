#!/bin/bash

if [[ $(hostname -s) = k8s-master* ]]; then

  ## Deploy Metal Load Balancer
	su vagrant -c "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/namespace.yaml"
	su vagrant -c "kubectl apply -f /vagrant/resources/metal-configmap.yaml"
	su vagrant -c "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/metallb.yaml"
	su vagrant -c "kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey=\"$(openssl rand -base64 128)\""

fi