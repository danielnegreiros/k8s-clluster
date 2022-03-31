#!/bin/bash

if [[ $(hostname -s) = k8s-master* ]]; then

  ## DashBord
  su vagrant -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml"
  su vagrant -c "kubectl apply -f /vagrant/resources/kubernetes-dashboard-sas.yaml"
  su vagrant -c "kubectl patch svc kubernetes-dashboard -n=kubernetes-dashboard -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"
  kubectl get secret --kubeconfig=/home/vagrant/.kube/config -n kubernetes-dashboard $(kubectl get serviceaccount  admin-user --kubeconfig=/home/vagrant/.kube/config -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode  > /home/vagrant/dashboard-token-admin
  kubectl get secret --kubeconfig=/home/vagrant/.kube/config -n kubernetes-dashboard $(kubectl get serviceaccount  read-only-user --kubeconfig=/home/vagrant/.kube/config -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode  > /home/vagrant/dashboard-token-read-only
  chown vagrant /home/vagrant/dashboard-token-*

fi