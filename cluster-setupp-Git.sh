#!/bin/bash

##################### Run this on your master node #######################

sudo ufw allow 6443/tcp
sudo ufw allow 2379/tcp
sudo ufw allow 2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10257/tcp
sudo ufw allow 10259/tcp
sudo ufw reload


cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
sudo modprobe br_netfilter


cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
sudo swapoff -a
echo "Please remove the swap entry from /etc/fstab !!!"

sudo rm -fr /etc/cni/net.d/*
DEBIAN_FRONTEND=noninteractive sudo apt -y update

sudo apt -y install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

DEBIAN_FRONTEND=noninteractive sudo apt -y update
DEBIAN_FRONTEND=noninteractive sudo apt -y upgrade

DEBIAN_FRONTEND=noninteractive sudo apt -y install kubelet kubeadm kubectl





OS=xUbuntu_20.04
CRIO_VERSION=1.23

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -
DEBIAN_FRONTEND=noninteractive sudo apt -y update
DEBIAN_FRONTEND=noninteractive sudo apt -y install cri-o cri-o-runc
sudo systemctl enable crio.service
sudo systemctl start crio.service
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config



kubectl get pods -A
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
sleep 3
kubectl get pods -A



