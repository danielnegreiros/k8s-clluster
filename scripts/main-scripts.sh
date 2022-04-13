#!/bin/bash
sudo -i 

## Set Vagrant password and allow password ssh
echo "test123" | passwd --stdin vagrant
sed -i 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
sudo systemctl restart sshd


## set hosts
cat << EOF >> /etc/hosts
192.168.50.10 k8s-master master
192.168.50.20 k8s-worker01 worker01
192.168.50.30 k8s-worker02 worker02
EOF

#ip=$(ip addr | grep 10.0.2 | awk '{print $2}' | awk -F "/" '{print $1}')
#echo "$ip   $(hostname)" >> /etc/hosts
# delete useless line
sudo sed -i '/127.0.1.1 k8s/d' /etc/hosts

# Configure required modules
# First load two modules in the current running environment and configure them to load on boot

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

# Fix repo
cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Apply sysctl parameters without reboot to current running environment
sudo sysctl --system

## set NTP
timedatectl set-timezone America/Sao_Paulo
yum update -y

## Install Docker and helper packages
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd vim curl dos2unix wget bash-completion iproute-tc

# Create a containerd configuration file
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Configure SystemdCgroup
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
# sudo sed -i 's/.containerd.runtimes.runc.options]/.containerd.runtimes.runc.options]\'$'\n                   SystemdCgroup = true/g' /etc/containerd/config.toml

## Enable and start docker
systemctl start containerd && systemctl enable containerd

## Install and enable kubernetes
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

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

## Set basic Iptables
# systemctl enable firewalld
# systemctl start firewalld
# firewall-cmd --add-masquerade --permanent
# firewall-cmd --add-port=30000-32767/tcp --permanent
# firewall-cmd --add-port=22/tcp --permanent
# firewall-cmd --add-port=80/tcp  --permanent
# firewall-cmd --add-port=8000/tcp  --permanent
# firewall-cmd --add-port=8080/tcp  --permanent
# firewall-cmd --add-port=443/tcp  --permanent
# firewall-cmd --add-port=4443/tcp  --permanent
# firewall-cmd --add-port=6443/tcp  --permanent
# firewall-cmd --add-port=8443/tcp  --permanent
# firewall-cmd --add-port=6783/tcp  --permanent
# firewall-cmd --add-port=2376/tcp  --permanent
# firewall-cmd --add-port=2379/tcp  --permanent
# firewall-cmd --add-port=2380/tcp  --permanent
# firewall-cmd --add-port=2377/tcp  --permanent
# firewall-cmd --add-port=7946/tcp  --permanent
# firewall-cmd --add-port=7946/udp  --permanent
# firewall-cmd --add-port=4789/tcp  --permanent
# firewall-cmd --add-port=4789/udp  --permanent
# firewall-cmd --add-port=10250/tcp --permanent
# firewall-cmd --add-port=10251/tcp --permanent
# firewall-cmd --add-port=10252/tcp --permanent
# sudo firewall-cmd --reload

## Disable swap (Kubernetes requirement)
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

## Disable SElinux
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux


## Set Banner
cat << EOF > /etc/profile.d/banner.sh
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
echo "|  git: https://gitlab.com/danielnegreirosb/k8s-cluster.git  |"
echo "|------------------------------------------------------------|"
EOF


## ssh no host check
su - vagrant -c "echo 'alias ssh=\"ssh -o StrictHostKeyChecking=no\"' >> ~/.bashrc"
su - vagrant -c "echo 'alias scp=\"scp -o StrictHostKeyChecking=no\"' >> ~/.bashrc"

## Allow members to perform ssh to other hosts to fetch join command
su - vagrant -c "echo \"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDebBanpsJE2nh63sFRyHK8w0lK50CE1lY7jn2r4qwXQjsI/b3JIfIcnCy+ZGLs51AAvwpBG7JWyYDZtipfHDJqAkI4v6hcduHyGCOPi6K7HkhGIJxHy6n6yEjCWllUlPVyEqnhQZBtb1gBbWni/9UcwWWnyRCLZakFp1MwWfOK8K3YyEx41whoa8gqAruyimaLHOfes/GnDOY84e7szu/QZUeONKKvQwvX7NRuncrKgtZqyEACcwfrCUBBcfaQaCxXpB7p4s0BIpdEXYEZsJw4RRS/mWWpBD23p29NCUXsc09hf1nH0L0VfSt3u32y0cYNC1HQtOiSNku6Yy05foaB vagrant@worker01\" >> ~/.ssh/authorized_keys"

# Fix proper interface in the kubeadm config file
sudo sed -i "s/config.yaml/config.yaml --node-ip=$1/g" /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

# Resart Containerd
sudo systemctl restart containerd
