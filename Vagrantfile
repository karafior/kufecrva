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
  if kubernetes_role == "master"
    vm_instance.vm.provider :libvirt do |domain|
      domain.memory = $vm_master_mem
      domain.cpus = $vm_master_cpus
    end
    vm_instance.vm.provider :virtualbox do |domain|
      domain.memory = $vm_master_mem
      domain.cpus = $vm_master_cpus
    end
  elsif kubernetes_role == "node"
    vm_instance.vm.provider :libvirt do |domain|
      domain.memory = $vm_node_mem
      domain.cpus = $vm_node_cpus
    end
    vm_instance.vm.provider :virtualbox do |domain|
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
  vm_instance.vm.provision "system_settings",
    type: "file",
    source: "files/etc/",
    destination: "/tmp/templates/"

  # Use shell provisioning to setup kubelet
  vm_instance.vm.provision "kubelet",
    type: "shell",
    path: "scripts/provision_kubelet.sh"

end

Vagrant.configure("2") do |config|

  config.vm.box = $os_image
  config.vm.synced_folder ".", "/home/vagrant/sync", disabled: true
  config.vm.synced_folder ".", "/vagrant/", disabled: true

  # We require either a DHCP with hostname resolution or the hostmanager plugin
  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = false
    config.hostmanager.include_offline = true
    config.vm.provision :hostmanager
  end

  # Provision masters
  $num_masters.times do |n|
    master_vm_name = "master#{n+1}"

    config.vm.define master_vm_name do |vm_instance|
      configure_vm(vm_instance, master_vm_name, "master")
      setup_kubelet(vm_instance)

      # Use shell script to setup the control plane
      if master_vm_name == "master1"
        vm_instance.vm.provision "master-init",
          type: "shell",
          args: [$kubeadm_token, $pod_network_cidr],
          path: "scripts/initialize_first_master.sh"
      else
        vm_instance.vm.provision "master-join",
          type: "shell",
          args: [$kubeadm_token, $pod_network_cidr],
          path: "scripts/initialize_other_masters.sh"
      end

    end
  end

  # Provision nodes
  $num_nodes.times do |n|
    node_vm_name = "node#{n+1}"

    config.vm.define node_vm_name do |vm_instance|
      configure_vm(vm_instance, node_vm_name, "node")
      setup_kubelet(vm_instance)

      # Use shell script to setup the control plane
      if $skip_ca_verification == true
        vm_instance.vm.provision "node-join",
          type: "shell",
          args: [$kubeadm_token],
          path: "scripts/join_node.sh"
      end

    end
  end

end
