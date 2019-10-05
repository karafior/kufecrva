# Kubernetes on Fedora with CRI-O via Vagrant 

## Work in progress

This setup is a work in progress. It has been tested on Fedora with a Vagrant + libvirt + dnsmasq setup, but currently fails to deploy on a typical Windows/Mac VirtualBox setup due a properly working dynamic hostname resolution.

## Caveats

### Vagrant parallel provisioning

Depending on your Vagrant provider and the use of `--[no-]parallel` option, you might observe kubelet connection errors when Nodes are trying to connect to the Control Plane. This is a race condition which occurs when parallel provisioning is enabled and should not affect your provisioning.  

The messages can be safely ignored as kubeadm will retry joining the Control Plane (until manually interrupted) and will eventually connect when Kubernetes API becomes ready.
