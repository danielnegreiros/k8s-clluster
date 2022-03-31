#!/bin/bash

if [[ $(hostname -s) = k8s-master* ]]; then

	## Install helm
	su vagrant -c "curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash"
  	su vagrant -c "/usr/local/bin/helm repo add stable https://charts.helm.sh/stable"

fi