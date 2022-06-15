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

sudo apt -y remove needrestart


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

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
helm repo add bitnami https://charts.bitnami.com/bitnami


#cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
#[crio.network]
#network_dir = "/etc/cni/net.d/"
#plugin_dirs = [
#    "/opt/cni/bin/",
#    "/usr/libexec/cni/",
#]
#EOF


cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
[crio.network]
network_dir = "/etc/cni/net.d/"
plugin_dirs = [
    "/usr/libexec/cni/",
    "/opt/cni/bin/",
 
]
EOF

cat  << EOF | sudo tee /var/lib/kubelet/kubeadm-flags.env
KUBELET_KUBEADM_ARGS="--cgroup-driver=systemd --container-runtime=remote --container-runtime-endpoint=unix:///var/run/crio/crio.sock --pod-infra-container-image=k8s.gcr.io/pause:3.7"
EOF

cat  << EOF | sudo tee /etc/cni/net.d/100-crio-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "crio",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "hairpinMode": true,
    "ipam": {
        "type": "host-local",
        "routes": [
            { "dst": "0.0.0.0/0" },
            { "dst": "1100:200::1/24" }
        ],
        "ranges": [
            [{ "subnet": "10.244.0.0/16" }],
            [{ "subnet": "1100:200::/24" }]
        ]
    }
}
EOF
sudo rm -fr /etc/cni/net.d/100-crio-bridge.conf
sudo systemctl daemon-reload


sudo systemctl enable crio.service
sudo systemctl start crio.service







sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config



kubectl get pods -A
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
sleep 3
kubectl get pods -A

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/cloud/deploy.yaml
#git clone https://github.com/scriptcamp/nginx-ingress-controller.git
kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-



curl https://projectcalico.docs.tigera.io/manifests/calico-typha.yaml -o calico.yaml
#kubectl apply -f calico.yaml

##kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'  
#kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
#kubectl port-forward svc/argocd-server -n argocd 8080:443 --address="0.0.0.0"


##kubectl create namespace kubeapps
##helm install kubeapps --namespace kubeapps bitnami/kubeapps
#   kubectl port-forward --namespace kubeapps service/kubeapps 8080:80

#for BREW
##sudo apt install build-essential git
##/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
##eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

#k9S
##brew install derailed/k9s/k9s

# helm
#sudo snap install helm --classic

#nfs-common
DEBIAN_FRONTEND=noninteractive sudo apt-get -y install nfs-common



#https://openebs.io/docs/user-guides/installation
#kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
#kubectl apply -f https://openebs.github.io/charts/cstor-operator.yaml

#kubectl get pods -n openebs

#kubectl get node --show-labels
#kubectl get bd -n openebs



#cat  << EOF | sudo tee ./csps.yaml
#apiVersion: cstor.openebs.io/v1
#kind: CStorPoolCluster
#metadata:
# name: cstor-disk-pool
# namespace: openebs
#spec:
# pools:
#   - nodeSelector:
#       kubernetes.io/hostname: "master"
#     dataRaidGroups:
#       - blockDevices:
#           - blockDeviceName: "blockdevice-e73b795418aa45dbc89156b3f8953f6b"
#     poolConfig:
#       dataRaidGroupType: "stripe"
#EOF
#kubectl apply -f ./csps.yaml

#cat  << EOF | tee ./cstor-disk.yaml
#kind: StorageClass
#apiVersion: storage.k8s.io/v1
#metadata:
#  name: cstor-csi-disk
##provisioner: cstor.csi.openebs.io
#allowVolumeExpansion: true
#parameters:
 # cas-type: cstor
  # cstorPoolCluster should have the name of the CSPC
  cstorPoolCluster: cstor-disk-pool
  # replicaCount should be <= no. of CSPI created in the selected CSPC
  replicaCount: "1"
#EOF

#kubectl apply -f ./cstor-disk.yaml


#kubectl get cspc -n openebs
#kubectl get cspi -n openebs

#kubectl get sc -A
#kubectl get cvc -A

#cat  << EOF | tee ./pesistent.yaml
#kind: PersistentVolumeClaim
#apiVersion: v1
#metadata:
#  name: cstor-pvc
#spec:
#  storageClassName: cstor-csi-disk
#  accessModes:
#    - ReadWriteOnce
#  resources:
#    requests:
#      storage: 5Gi
#EOF

#kubectl apply -f ./pesistent.yaml


#cat << EOF | tee ./busybox.yml
#apiVersion: v1
#kind: Pod
#metadata:
#  name: busybox
#  namespace: default
#spec:
#  containers:
#  - command:
#       - sh
#       - -c
#       - 'date >> /mnt/openebs-csi/date.txt; hostname >> /mnt/openebs-csi/hostname.txt; sync; sleep 5; sync; tail -f /dev/null;'
#    image: busybox
#    imagePullPolicy: Always
#    name: busybox
#    volumeMounts:
#    - mountPath: /mnt/openebs-csi
#      name: demo-vol
#  volumes:
#  - name: demo-vol
#    persistentVolumeClaim:
#      claimName: cstor-pvc
#EOF

#kubectl apply -f busybox.yml


cat << EOF | tee ./nfs-pv.yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: nfs
  mountOptions:
    - hard
  nfs:
    path: /data/storage
    server: nas.fritz.box
EOF

kubectl apply -f ./nfs-pv.yml



cat << EOF | tee ./nfs-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  storageClassName: nfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF
kubectl apply -f ./nfs-pvc.yml

cat << EOF | tee ./busybox.yml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - command:
       - sh
       - -c
       - 'while true; do date > /mnt/storage/index.html; hostname >> /mnt/storage/index.html; sleep 7; done'
    image: busybox
    imagePullPolicy: Always
    name: busybox
    volumeMounts:
    - mountPath: /mnt/storage
      name: demo-vol
  volumes:
  - name: demo-vol
    persistentVolumeClaim:
      claimName: nfs-pvc
EOF
kubectl apply -f ./busybox.yml
