#!/bin/bash 

exec > /var/log/user-data.log 2>&1
set -x
#Ubuntu
#Containerd:

sudo -i
whoami
hostnamectl set-hostname k8s-master

#Step 1:
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

#STep2:  Disable Swap

sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

#Step3 : Installing Container Runtime - Containerd

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd-0.3.15.amd64.tgz

sudo tar -xvf cri-dockerd-0.3.15.amd64.tgz
sudo mv cri-dockerd /usr/local/bin/

# Configure cri-dockerd
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
sudo mv cri-docker.socket cri-docker.service /etc/systemd/system/
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service

# Modify cri-docker-service file

SERVICE_FILE="/etc/systemd/system/cri-docker.service"
cp $SERVICE_FILE "$SERVICE_FILE.bak"
sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/local/bin/cri-dockerd/cri-dockerd --container-runtime-endpoint unix:///var/run/cri-dockerd.sock|' $SERVICE_FILE

sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
START

#containerd config file
CONFIG_FILE="/etc/containerd/config.toml"
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
echo "Backup of the config file created as $CONFIG_FILE.bak"
sudo sed -i 's/^\(disabled_plugins = \[\(.*\)\]\)/# \1/' "$CONFIG_FILE"

sudo systemctl restart containerd
STOP
# sudo systemctl stop containerd
# #Step 4: Load default container configuration using below command and enable cgroup systemd driver for interacting cgroup interface for physical resources.

# containerd config default > /etc/containerd/config.toml

#Configuring the systemd cgroup driver
#To use the systemd cgroup driver in /etc/containerd/config.toml with runc, set

#[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
 # ...
  #[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    #SystemdCgroup = true
#sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
#systemctl status  containerd
#systemctl restart  containerd


#Installing kubeadm, kubelet and kubectl 
#These instructions are for Kubernetes v1.30.

sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package

#sudo apt install net-tools -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
#Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#Add the appropriate Kubernetes apt repository. Please note that this repository have packages only for Kubernetes 1.30; for other Kubernetes minor versions, you need to change the Kubernetes minor version in the URL to match your desired minor version (you should also check that you are reading the documentation for the version of Kubernetes that you plan to install).
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list


sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sleep 10s
sudo systemctl start cri-docker.service
sudo systemctl status cri-docker.service
sudo systemctl status docker.service
sudo systemctl status kubelet.service
#(Optional) Enable the kubelet service before running kubeadm:

#sudo systemctl enable --now kubelet
sleep 30s
# Initialize the cluster using kubeadm 
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4)
echo $PRIVATE_IP
kubeadm init --apiserver-advertise-address=$PRIVATE_IP --pod-network-cidr=192.168.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock
#kubeadm init --apiserver-advertise-address=172.31.4.23 --pod-network-cidr=192.168.0.0/16 --cri-socket unix:///var/run/containerd/containerd.sock

# sleep 10
# su - ubuntu

mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install zip -y
unzip awscliv2.zip
sudo ./aws/install
sudo kubeadm token create --print-join-command > /etc/kubernetes/join-command.txt
aws s3 cp /etc/kubernetes/join-command.txt s3://ssoin5/join-command.txt
export KUBECONFIG=/etc/kubernetes/admin.conf
echo $KUBECONFIG

# # Install Calico
sleep 40s
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml -O
kubectl --kubeconfig=$KUBECONFIG apply -f calico.yaml 

# if in case getting error while installing calico.yml
# error: error validating "calico.yaml": error validating data: failed to download openapi: Get "http://localhost:8080/openapi/v2?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false

# run below command using root

#export KUBECONFIG=/etc/kubernetes/admin.conf

# kubectl get po -A

# su - ubuntu 
# kubectl get po -A