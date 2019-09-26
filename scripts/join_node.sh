kubeadm join master1:6443 \
  --cri-socket=unix:///var/run/crio/crio.sock \
  --discovery-token-unsafe-skip-ca-verification \
  --ignore-preflight-errors=SystemVerification \
  --token ${1}
