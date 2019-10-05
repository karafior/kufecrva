#!/bin/bash

KUBE_VERSION=${1}

# Copy template files and reload system settings

cp /tmp/templates/etc/modules-load.d/br_netfilter.conf /etc/modules-load.d/br_netfilter.conf
cp /tmp/templates/etc/sysconfig/kubelet /etc/sysconfig/kubelet
cp /tmp/templates/etc/sysctl.d/k8s.conf /etc/sysctl.d/k8s.conf
cp /tmp/templates/etc/yum.repos.d/kubernetes.repo /etc/yum.repos.d/kubernetes.repo

systemctl restart systemd-modules-load.service
sysctl --system
modprobe br_netfilter

# Enable CRI-O module and install required RPMs

dnf --assumeyes module enable cri-o:${KUBE_VERSION}
#rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
dnf --assumeyes install \
  --disableexcludes=kubernetes \
  cri-o \
  cri-tools \
  conmon \
  kubeadm-${KUBE_VERSION}.* \
  kubectl-${KUBE_VERSION}.* \
  kubelet-${KUBE_VERSION}.* \
  kubernetes-cni

# Enable and start required systemd units

systemctl enable --now crio.service kubelet.service
