# -*- mode: ruby -*-
# vim: expandtab shiftwidth=2 softtabstop=2 ft=ruby

# Load local env config
require 'yaml'
dir = File.dirname(File.expand_path(__FILE__))

# defaults
config = YAML::load_file("#{dir}/config/defaults.yaml")

if File.exist?("#{dir}/config/config.yaml")
  config_settings = YAML::load_file("#{dir}/config/config.yaml")
  config.merge!(config_settings)
end

# The number of masters to provision
$num_masters = (ENV['NUM_MASTERS'] || config["num_masters"]).to_i

# The number of nodes to provision
$num_nodes = (ENV['NUM_NODES'] || config["num_nodes"]).to_i

# Determine the OS platform to use
$os_image = ENV['OS_IMAGE'] || config["os_image"]

# Define the number of CPUs
$vm_master_cpus = (ENV['MASTER_CPUS'] || ENV['CPUS'] || config["vm_master_cpus"]).to_i
$vm_node_cpus = (ENV['NODE_CPUS'] || ENV['CPUS'] || config["vm_node_cpus"]).to_i

# Define the ammount of RAM
$vm_master_mem = (ENV['MASTER_MEMORY'] || ENV['MEMORY'] || config["vm_master_mem"]).to_i
$vm_node_mem = (ENV['NODE_MEMORY'] || ENV['MEMORY'] || config["vm_node_mem"]).to_i

# Define the kubeadm token used for joining the cluster
$kubeadm_token = (ENV['KUBADM_TOKEN'] || config["kubeadm_token"]).to_s

# Ignore master certificate verification when joining the cluster
$skip_ca_verification = (ENV['SKIP_CA_VERIFICATION'] || config["skip_ca_verification"])

# Define the subnet for CNI
$pod_network_cidr = (ENV['POD_NETWORK_CIDR'] || config["pod_network_cidr"])

def configure_vm(vm_instance, vm_name, kubernetes_role)
  #vm_instance.vm.hostname = master_vm_name
  vm_instance.vm.provider :libvirt do |domain|
    if kubernetes_role == "master"
      domain.memory = $vm_master_mem
      domain.cpus = $vm_master_cpus
    elsif kubernetes_role == "node"
      domain.memory = $vm_node_mem
      domain.cpus = $vm_node_cpus
    end
  end

  # Use shell provisioning to setup a hostname and register it in DNS
  vm_instance.vm.provision "shell" do |s|
    s.inline = <<-SHELL
      hostnamectl set-hostname ${1}
      nmcli con up "System eth0"
      SHELL
    s.args = [vm_name]
  end
end

def setup_kubelet(vm_instance)
  # Use file provisioning to setup repositories and sysctl's
  vm_instance.vm.provision "file", source: "files/etc/", destination: "/tmp/templates/"

  # Use shell provisioning to setup kubelet
  vm_instance.vm.provision "kubelet",
    type: "shell",
    path: "scripts/provision_kubelet.sh"
end

def join_node(vm_instance)
  vm_instance.vm.provision "node-join",
    type: "shell",
    args: $kubeadm_token,
    inline: <<-SHELL
      kubeadm join master1:6443 \
        --cri-socket=unix:///var/run/crio/crio.sock \
        --discovery-token-unsafe-skip-ca-verification \
        --ignore-preflight-errors=SystemVerification \
        --token ${1}
    SHELL
end

Vagrant.configure("2") do |config|

  config.vm.box = $os_image
  config.vm.synced_folder ".", "/home/vagrant/sync", disabled: true
  config.vm.synced_folder ".", "/vagrant/", disabled: true

  # Provision masters
  $num_masters.times do |n|
    master_vm_name = "master#{n+1}"

    config.vm.define master_vm_name do |vm_instance|
      configure_vm(vm_instance, master_vm_name, "master")
      setup_kubelet(vm_instance)

      # Use shell provisioning to setup first master
      if master_vm_name == "master1"
        vm_instance.vm.provision "master-init",
          type: "shell",
          args: [$kubeadm_token, $pod_network_cidr],
          inline: <<-SHELL
            kubeadm init \
              --cri-socket=unix:///var/run/crio/crio.sock \
              --ignore-preflight-errors=SystemVerification \
              --token=${1} \
              --token-ttl=1h \
              --pod-network-cidr=${2}
            mkdir -p /root/.kube
            cp -i /etc/kubernetes/admin.conf /root/.kube/config
          SHELL
      else
        vm_instance.vm.provision "master-join",
          type: "shell",
          args: master_vm_name,
          inline: <<-SHELL
            kubeadm init \
              phase mark-control-plane \
              --node-name ${1}
          SHELL
      end

    end
  end

  # Provision nodes
  $num_nodes.times do |n|
    node_vm_name = "node#{n+1}"

    config.vm.define node_vm_name do |vm_instance|
      configure_vm(vm_instance, node_vm_name, "node")
      setup_kubelet(vm_instance)

    end
  end

  config.trigger.after :up do |t|
    t.name = "Hello world"
    t.info = "Trigger running after vagrant up"
    $num_nodes.times do |n|
      node_vm_name = "node#{n+1}"

      config.vm.define node_vm_name do |vm_instance|
        if $skip_ca_verification == true
          join_node(vm_instance)
        end
      end
    end
  end

end
