#!/bin/bash

# Copy template files and reload system settings

cp /tmp/templates/etc/modules-load.d/br_netfilter.conf /etc/modules-load.d/br_netfilter.conf
cp /tmp/templates/etc/sysconfig/kubelet /etc/sysconfig/kubelet
cp /tmp/templates/etc/sysctl.d/k8s.conf /etc/sysctl.d/k8s.conf
cp /tmp/templates/etc/yum.repos.d/kubernetes.repo /etc/yum.repos.d/kubernetes.repo

systemctl restart systemd-modules-load.service
sysctl --system
modprobe br_netfilter

# Enable CRI-O module and install required RPMs

dnf --assumeyes module enable cri-o:1.13
#rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
dnf --assumeyes install \
  --disableexcludes=kubernetes \
  cri-o \
  cri-tools \
  conmon \
  kubelet-1.13.10-0 \
  kubeadm-1.13.10-0 \
  kubectl-1.13.10-0 \
  kubernetes-cni

# Enable and start required systemd units

systemctl enable --now crio.service kubelet.service
