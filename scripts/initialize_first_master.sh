kubeadm init \
  --cri-socket=unix:///var/run/crio/crio.sock \
  --ignore-preflight-errors=SystemVerification \
  --token=${1} \
  --token-ttl=1h \
  --pod-network-cidr=${2}

mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Setup Flannel networking
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
systemctl restart crio.service kubelet.service
