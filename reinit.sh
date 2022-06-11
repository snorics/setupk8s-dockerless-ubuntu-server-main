sudo kubeadm reset
sudo rm -fr /etc/cni/net.d
sudo rm /etc/containerd/config.toml
sudo rm -rf /etc/cni/net.d/*

sudo systemctl restart containerd
sudo modprobe overlay
sudo modprobe br_netfilter
sudo systemctl restart kubelet
sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 
#sudo kubeadm init --pod-network-cidr=10.0.0.0/16 --apiserver-advertise-address=192.168.178.86 --control-plane-endpoint=192.168.178.86
#sudo kubeadm alpha certs renew all
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
sleep 10
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml


#kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-

#curl https://docs.projectcalico.org/manifests/calico.yaml > calico.yaml
#kubectl apply -f ./calico.yaml
#sleep 10

#kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
#kubectl create -f https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml
#kubectl taint nodes --all node-role.kubernetes.io/master-



