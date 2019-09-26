
## Kubernetes Metrics Server
The `metrics-server` is a replacement for Heapster and is required for `kubectl top ...` or auto scaling to operate properly.

```bash
# Clone the GitHub repo
git clone https://github.com/kubernetes-incubator/metrics-server.git

# Apply the YAMLs for the cluster version of your choosing
kubectl apply -f ./metrics-server/deploy/1.8+/

# Patch the deployment to skip TLS verification and be more suitable for Vagrant environments
kubectl patch deploy/metrics-server \
 --namespace kube-system \
 --type='json' \
 --patch='[{"op":"add","path":"/spec/template/spec/containers/0/args","value": ["--kubelet-insecure-tls","--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"]}]'
```

## Kubernetes Dashboard 

```bash
# Apply the YAMLs for the current version of the dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml

# Expose the dashboard via a proxy
kubectl proxy --address='0.0.0.0' --accept-hosts='.*'
```
