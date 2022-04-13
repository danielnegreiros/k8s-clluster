#!/bin/bash
if [[ $(hostname -s) = k8s-worker* ]]; then
  	## as root
	sudo -i
	## enable kubelet
    systemctl enable kubelet
    ## Transfer keys to workers. With this key it can access master passwordless with vagrant user
	su - vagrant -c "cp /vagrant/scripts/id_rsa /home/vagrant/.ssh/"
	su - vagrant -c "cp /vagrant/scripts/id_rsa.pub /home/vagrant/.ssh/" 
	chmod 400 /home/vagrant/.ssh/*

	## Fetch join token on master
	while ! su - vagrant -c "scp -o StrictHostKeyChecking=no vagrant@master:/tmp/master-join-command.sh /tmp/"
	do
		sleep 30
	done

	chmod +x /tmp/master-join-command.sh
  	## Use retrieved script to join cluster
	bash /tmp/master-join-command.sh
fi

