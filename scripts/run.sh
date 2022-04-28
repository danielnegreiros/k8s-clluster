
ip=$1
cidr=$2
role=$3
pass=$4
fea_dash=$5
fea_helm=$6
fea_met=$7
fea_mlb=$8
fea_dsc=$9

set_conn(){
    ## Allow password ssh
    echo vagrant:$pass | sudo chpasswd
    sudo sed -i 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
    sudo systemctl restart sshd

    ## ssh no host check
    echo 'alias ssh="ssh -o StrictHostKeyChecking=no"' >> ~/.bashrc
    echo 'alias scp="scp -o StrictHostKeyChecking=no"' >> ~/.bashrc

}

copy_keys(){
    ## Copy keys
    this_user=$USER
	sudo cp /vagrant/scripts/id_rsa ~/.ssh/
	sudo cp /vagrant/scripts/id_rsa.pub ~/.ssh/
	sudo chmod 400 /home/$this_user/.ssh/id*
    sudo chown -R $USER:$USER /home/$this_user/.ssh/

    ## Allow members to perform ssh to other hosts to fetch join command
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
}


fix_hosts(){
    sudo sed -i '/127.0.1.1 k8s/d' /etc/hosts
}

config_modules(){
    
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF


# Configure required sysctl to persist across system reboots
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl parameters without reboot to current running environment
sudo sysctl --system
}


fix_repo(){
    cd /etc/yum.repos.d/
    sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
    sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
    sudo yum update -y
}

install_containerd_pkgs(){
    
    ## Install containerd and helper packages
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y containerd vim curl dos2unix wget bash-completion iproute-tc

    # Create a containerd configuration file
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml

    # Configure SystemdCgroup
    sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
    # sudo sed -i 's/.containerd.runtimes.runc.options]/.containerd.runtimes.runc.options]\'$'\n                   SystemdCgroup = true/g' /etc/containerd/config.toml

    ## Enable and start docker
    sudo systemctl start containerd 
    sudo systemctl enable containerd
}

install_kubernetes(){
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

## Disable swap (Kubernetes requirement)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

## Disable SElinux
sudo setenforce 0
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# Fix proper interface in the kubeadm config file
sudo sed -i "s/config.yaml/config.yaml --node-ip=$1/g" /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
}


set_banner(){
    sudo tee /etc/profile.d/banner.sh << EOF
clear
echo "|------------------------------------------------------------|"
echo "|                                                            |"
echo "|        | |   / _ \       / ____| |         | |             |"
echo "|        | | _| (_) |___  | |    | |_   _ ___| |_ ___ _ __   |"
echo "|        | |/ /> _ </ __| | |    | | | | / __| __/ _ \ '__|  |"
echo "|        |   <| (_) \__ \ | |____| | |_| \__ \ ||  __/ |     |"
echo "|        |_|\_/\___/|___/  \_____|_|\__,_|___/\__\___|_|     |"
echo "|                                                            |"
echo "|  Questions:          1:3   PODs         4:6   ReplicaSet   |"
echo "|  7:9   Deployments   10:13 Labels      14:17  Resources    |"
echo "|  18:20 AutoScaling   21-23 Services    24:28  Scheduling   |"
echo "|                                                            |"
echo "|           i.e: question1 -> hint1 -> submit1               |"
echo "|                                                            |"
echo "|          To see banner again, type: banner                 |"
echo "|   git: https://github.com/danielnegreiros/k8s-cluster      |"
echo "|------------------------------------------------------------|"
EOF
}


set_questions(){
    ## Prepare exercises
	sudo dos2unix /vagrant/resources/q/* > /dev/null 2>&1
	sudo dos2unix /vagrant/resources/a/* > /dev/null 2>&1
	sudo chmod +x /vagrant/resources/q/*
	sudo cp /vagrant/resources/q/*  /usr/local/bin/
}

install_master_helper_pkgs(){
    ## Install etcd-client
	curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4  | wget -qi - && sleep 10
	tar -xvf etcd*.tar.gz
	sudo mv etcd-v*-linux-amd64/etcdctl /usr/local/bin/
	rm -rf etcd-*

    ## Install jq
	sudo yum install epel-release -y
	sudo yum update -y
	sudo yum install httpd-tools jq git -y
}

config_k8s(){
    ## Init Kubernetes
	echo "kubeadm init --apiserver-advertise-address $ip --pod-network-cidr=$cidr"
	sudo kubeadm init --apiserver-advertise-address $ip --pod-network-cidr=$cidr
    mkdir -p ~/.kube
	touch ~/.kube/config
	sudo cp -Rf /etc/kubernetes/admin.conf ~/.kube/config
    chmod 600 ~/.kube/config
	## Enable service
	sudo systemctl enable kubelet
    ## Install cni networking
	#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
	kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')
    ## Create joining token for workers
	kubeadm token create --print-join-command --ttl 0 > /tmp/master-join-command.sh
    
    ## Config auto-completion
	echo "source <(kubectl completion bash)" >> ~/.bashrc
}

config_worker(){
	## enable kubelet
    sudo systemctl enable kubelet

	## Fetch join token on master
	while ! scp -o StrictHostKeyChecking=no vagrant@k8s-master:/tmp/master-join-command.sh /tmp/
	do
		sleep 30
	done

	chmod +x /tmp/master-join-command.sh
  	## Use retrieved script to join cluster
	sudo bash /tmp/master-join-command.sh
}


fea_dash_ac(){
    ## DashBoard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.1/aio/deploy/recommended.yaml
    kubectl apply -f /vagrant/resources/kubernetes-dashboard-sas.yaml
    kubectl patch svc kubernetes-dashboard -n=kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'
    kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount  admin-user -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode  > ~/dashboard-token-admin
    kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount  read-only-user -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode  > ~/dashboard-token-read-only
}

fea_helm_ac(){
    ## Install helm
	curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  	/usr/local/bin/helm repo add stable https://charts.helm.sh/stable
}

fea_met_ac(){
    kubectl apply -f /vagrant/resources/metrics-server.yaml
}

fea_mlb_ac(){
    ## Deploy Metal Load Balancer
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
	kubectl apply -f /vagrant/resources/metal-configmap.yaml
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
	kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
}

set_nfs(){
    sudo apt install nfs-kernel-server -y
    sudo systemctl start nfs-server
    sudo systemctl enable nfs-server
    sudo mkdir -p /srv/nfs/mydata
    sudo chmod -R 777 /srv/nfs/mydata  # for simple use but not advised

    sudo tee /etc/exports << EOF 
    /srv/nfs/mydata  *(rw,sync,no_subtree_check,no_root_squash,insecure)
EOF

    sudo exportfs -rv
    showmount -e
    sudo systemctl restart nfs-server
}

wa_conn_bug(){
    sudo yum install fping -y
    echo 'fping  -g 192.168.0.0/24 -c 5' >> ~/.bashrc
}

create_dync_sc_prov(){
    kubectl create ns provisioner
    sudo yum install nfs-utils -y
    mkdir provisioner
    cd provisioner

    tee rbac.yaml << EOF
kind: ServiceAccount
apiVersion: v1
metadata:
  name: nfs-pod-provisioner-sa
  namespace: provisioner
---
kind: ClusterRole # Role of kubernetes
apiVersion: rbac.authorization.k8s.io/v1 # auth API
metadata:
  name: nfs-provisioner-clusterRole
rules:
  - apiGroups: [""] # rules on persistentvolumes
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-provisioner-rolebinding
subjects:
  - kind: ServiceAccount
    name: nfs-pod-provisioner-sa # defined on top of file
    namespace: provisioner
roleRef: # binding cluster role to service account
  kind: ClusterRole
  name: nfs-provisioner-clusterRole # name defined in clusterRole
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-pod-provisioner-otherRoles
  namespace: provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-pod-provisioner-otherRoles
  namespace: provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-pod-provisioner-sa # same as top of the file
    # replace with namespace where provisioner is deployed
    namespace: provisioner
roleRef:
  kind: Role
  name: nfs-pod-provisioner-otherRoles
  apiGroup: rbac.authorization.k8s.io
EOF

    # Apply
    kubectl apply -f rbac.yaml

    tee sc.yaml << EOF 
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  namespace: provisioner
  name: nfs-storageclass  # IMPORTANT pvc needs to mention this name
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: nfs-provisioner   # name can be anything
reclaimPolicy: Delete
parameters:
  archiveOnDelete: "false"
EOF

    # Apply
    kubectl apply -f sc.yaml

    tee provisioner.yaml << EOF 
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-client-provisioner
  namespace: provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-pod-provisioner-sa
      containers:
        - name: nfs-client-provisioner
          image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: nfs-provisioner
            - name: NFS_SERVER
              value: NFS_IP
            - name: NFS_PATH
              value: /srv/nfs/mydata/
      volumes:
        - name: nfs-client-root
          nfs:
            server: NFS_IP
            path: /srv/nfs/mydata/
EOF

    # Apply
    nfs_ip=$(awk /nfs/'{print $1}' /etc/hosts)
    sed -i  s/NFS_IP/$nfs_ip/g provisioner.yaml
    kubectl apply -f provisioner.yaml

    cd ~ 
}

# Starting ....
set_conn
sudo timedatectl set-timezone America/Sao_Paulo

if [[ $role = master ]] || [[ $role = worker ]] ; then
    # Common actions
    copy_keys
    fix_hosts
    config_modules

    fix_repo
    install_containerd_pkgs
    install_kubernetes
    set_banner

    # Resart Containerd
    sudo systemctl restart containerd
fi

if [[ $role = master ]]; then
    set_questions
    install_master_helper_pkgs
    config_k8s

    ## Copy certificates so we are able to access etcd server
	sudo cp -r /etc/kubernetes/pki/etcd/ ~    

    if [[ $fea_dash = "Y" ]]; then
        fea_dash_ac
    fi

    if [[ $fea_helm = "Y" ]]; then
        fea_helm_ac
    fi

    if [[ $fea_met = "Y" ]]; then
        fea_met_ac
    fi

    if [[ $fea_mlb = "Y" ]]; then
        fea_mlb_ac
    fi
	

    if [[ $fea_dsc = "Y" ]]; then
        create_dync_sc_prov
    fi
    
    # wa_conn_bug
    create_dync_sc_prov
fi

if [[ $role = worker ]]; then
    config_worker  	
fi


if [[ $role = nfs ]]; then
    set_conn
    set_nfs  	
fi


# Bye 
sleep 30
echo "Finished successfully"
sudo reboot

