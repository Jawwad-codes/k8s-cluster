# -*- mode: ruby -*-
# vi: set ft=ruby :

# ================= CONFIG (edit here if needed) =================
BOX_IMAGE       = "ubuntu/jammy64"
MASTER_IP       = "192.168.56.10"
WORKER_IPS      = ["192.168.56.11", "192.168.56.12", "192.168.56.13"]
MASTER_CPU      = 2
MASTER_MEM      = 2048
WORKER_CPU      = 2
WORKER_MEM      = 2048
PUB_KEY_PATH    = File.join(File.dirname(__FILE__), "keys", "k8s-key.pub")
# ===================================================================

# Fail fast with a clear message if the SSH keypair hasn't been generated yet
unless File.exist?(PUB_KEY_PATH)
  raise "SSH public key not found at #{PUB_KEY_PATH}.\nRun ./scripts/generate-ssh-key.sh first (see README.md)."
end
PUB_KEY = File.read(PUB_KEY_PATH).strip

Vagrant.configure("2") do |config|
  config.vm.box = BOX_IMAGE
  config.vm.box_check_update = false

  # Inject our own SSH key into every VM so you can do:
  #   ssh -i keys/k8s-key vagrant@<ip>
  # just like an EC2 instance.
  config.vm.provision "ssh-key", type: "shell", inline: <<-SHELL
    mkdir -p /home/vagrant/.ssh
    echo "#{PUB_KEY}" >> /home/vagrant/.ssh/authorized_keys
    sort -u /home/vagrant/.ssh/authorized_keys -o /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
    chmod 700 /home/vagrant/.ssh
    chmod 600 /home/vagrant/.ssh/authorized_keys
  SHELL

  # ---------------- MASTER ----------------
  config.vm.define "k8s-master" do |master|
    master.vm.hostname = "k8s-master"
    master.vm.network "private_network", ip: MASTER_IP
    master.vm.provider "virtualbox" do |vb|
      vb.name   = "k8s-master"
      vb.cpus   = MASTER_CPU
      vb.memory = MASTER_MEM
    end
    master.vm.provision "shell", path: "scripts/common.sh", args: [MASTER_IP] + WORKER_IPS
    master.vm.provision "shell", path: "scripts/master.sh", args: [MASTER_IP]
  end

  # ---------------- WORKERS ----------------
  WORKER_IPS.each_with_index do |ip, i|
    n = i + 1
    config.vm.define "k8s-worker#{n}" do |worker|
      worker.vm.hostname = "k8s-worker#{n}"
      worker.vm.network "private_network", ip: ip
      worker.vm.provider "virtualbox" do |vb|
        vb.name   = "k8s-worker#{n}"
        vb.cpus   = WORKER_CPU
        vb.memory = WORKER_MEM
      end
      worker.vm.provision "shell", path: "scripts/common.sh", args: [MASTER_IP] + WORKER_IPS
      worker.vm.provision "shell", path: "scripts/worker.sh"
    end
  end
end
