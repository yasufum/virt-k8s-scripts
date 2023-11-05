function set_bridge() {
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
}

function swapoff() {
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
sudo rm -f /swap.img
}

function install_containerd_pkgs() {
sudo apt-get update -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo apt install -y \
	ca-certificates \
	curl \
	gnupg \
	lsb-release \
	apt-transport-https \
	nfs-common
}

function setup_docker_keyring() {
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
	"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}

function install_containerd() {
sudo apt-get update
sudo apt-get install containerd.io -y
sudo systemctl start containerd
sudo systemctl enable containerd

# https://github.com/containerd/containerd/issues/4581
sudo rm -f /etc/containerd/config.toml
sudo systemctl restart containerd
}

function update_cgroups_driver() {
sudo mv /etc/containerd/config.toml /etc/containerd/config.toml.orig
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
}

function install_nerdctl() {
wget https://github.com/containerd/nerdctl/releases/download/v1.6.0/nerdctl-1.6.0-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local/bin nerdctl-1.6.0-linux-amd64.tar.gz
}

function setup_k8s_keyring() {
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
}

function install_kubeadm() {
sudo apt-get install -y kubectl kubelet kubeadm
sudo apt-mark hold kubelet kubeadm kubectl
}

function install_cni_plugin() {
sudo mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz" | sudo tar -C /opt/cni/bin -xz
}

set_bridge
swapoff
install_containerd_pkgs
setup_docker_keyring
install_containerd
update_cgroups_driver
install_nerdctl
setup_k8s_keyring
install_kubeadm
install_cni_plugin
