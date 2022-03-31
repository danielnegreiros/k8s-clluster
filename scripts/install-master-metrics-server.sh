#!/bin/bash

if [[ $(hostname -s) = k8s-master* ]]; then


	## Install metrics server
	su vagrant -c "kubectl apply -f /vagrant/resources/metrics-server.yaml"

fi