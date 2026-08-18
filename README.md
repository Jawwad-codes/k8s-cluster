# Local Kubernetes Cluster with Vagrant

This project spins up a small Kubernetes cluster on your machine using Vagrant and VirtualBox. You get:

- 1 control-plane node
- 3 worker nodes
- automatic provisioning with kubeadm
- a shared SSH key for easy access

It’s a quick way to test Kubernetes locally without setting up each VM by hand.

## Requirements

Before you start, make sure you have:

- VirtualBox installed
- Vagrant installed
- enough free RAM available

A good rule of thumb is to leave around 9 GB free for the cluster. If you want to lower memory usage, adjust `MASTER_MEM` and `WORKER_MEM` in the `Vagrantfile`. Just don’t go below the kubeadm minimums for a node.

## One-time setup

From the project directory, run:

```bash
cd k8s-vagrant-cluster
chmod +x scripts/*.sh
./scripts/generate-ssh-key.sh
vagrant up
```

What this does:

1. Creates the SSH key pair in `keys/k8s-key` and `keys/k8s-key.pub`
2. Brings up the master VM and initializes Kubernetes
3. Installs the required Kubernetes components and Flannel networking
4. Starts the worker VMs and has them join the cluster automatically
5. Copies your public key into each VM’s `vagrant` user account

The whole process usually takes about 10–15 minutes depending on your internet speed.

## Connecting to the nodes

Once the machines are up, you can SSH in like this:

```bash
ssh -i keys/k8s-key vagrant@192.168.56.10   # master
ssh -i keys/k8s-key vagrant@192.168.56.11   # worker1
ssh -i keys/k8s-key vagrant@192.168.56.12   # worker2
ssh -i keys/k8s-key vagrant@192.168.56.13   # worker3
```

## Verifying the cluster

SSH into the master node and check the nodes:

```bash
ssh -i keys/k8s-key vagrant@192.168.56.10
kubectl get nodes -o wide
```

After a minute or two, you should see the master marked as `Ready` with the control-plane label, along with the three worker nodes also showing `Ready`.

## Useful Vagrant commands

```bash
vagrant status
vagrant halt
vagrant up
vagrant destroy -f
vagrant reload --provision
```

A quick cheat sheet:

- `vagrant status` — see current VM state
- `vagrant halt` — stop everything
- `vagrant up` — start the cluster again
- `vagrant destroy -f` — blow it all away and start from scratch
- `vagrant reload --provision` — re-run provisioning on running VMs

## Notes

- The cluster uses static private IPs: master at `192.168.56.10` and workers at `.11`, `.12`, and `.13`.
- If that IP range conflicts with something on your machine, update the addresses near the top of the `Vagrantfile`.
- The pod network is `10.244.0.0/16`, which is the default Flannel range.
- Kubernetes is pinned to version `1.30` in `scripts/common.sh`.
- If `vagrant up` fails halfway through, just run it again. The setup scripts are designed to be repeatable and skip work that has already been completed.

## Quick summary

If you just want the short version:

```bash
cd k8s-vagrant-cluster
chmod +x scripts/*.sh
./scripts/generate-ssh-key.sh
vagrant up
ssh -i keys/k8s-key vagrant@192.168.56.10
kubectl get nodes -o wide
```

That’s it — a working local Kubernetes cluster, ready to explore.
