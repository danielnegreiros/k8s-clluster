#!/bin/bash

if [[ $(hostname -s) = k8s-master* ]]; then

	## Deploy Ingress Controller
	su vagrant -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.1/deploy/static/provider/baremetal/deploy.yaml"
    ## su vagrant -c "kubectl delete -f /vagrant/resources/ingress-controller.yaml"

fi

if [[ $(hostname -s) = k8s-worker*2 ]]; then
  sudo -i
  sleep 30
  su - vagrant -c "ssh vagrant@master -o StrictHostKeyChecking=no  \"/usr/local/bin/helm install -n=app my-ingress-test /vagrant/resources/my-ingress-test/\""
fi

