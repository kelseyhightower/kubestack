# Kubestack

Provision a Kubernetes cluster with [Packer](https://packer.io) and [Terraform](https://www.terraform.io) on Google Compute Engine.

## Status

Currently Kubestack only works for my environment, but I'm publishing the bits so you can learn from it. Over the next couple of weeks the repo should be generic enough for reuse with complete documentation.

## Prep

- [Install Packer](https://packer.io/docs/installation.html)
- [Install Terraform](https://www.terraform.io/intro/getting-started/install.html)
- [Setup an Authentication JSON File](https://www.terraform.io/docs/providers/google/index.html#account_file)

The Packer and Terraform configs assume your authentication JSON file is stored under `/etc/kubestack-account.json`

## Packer Images

Immutable infrastructure is the future. Instead of using cloud-init to provision machines at boot we'll create custom images using Packer for the Kubernetes server and worker machines.

Run the packer commands below will create the following images:

```
kubestack-0-0-1-v20150517
kubestack-server-0-0-1-v20150517
kubestack-worker-0-0-1-v20150517
```

### Create the Kubestack Base Image

```
cd packer
packer build kubestack.json
```

### Create the Kubestack Server Image

```
packer build kubestack-server.json
```

### Create the Kubestack Worker Image

```
packer build kubestack-worker.json
```

## Terraform

Terraform will be used to declare and provision a Kubernetes cluster.

### Prep

Edit `terraform/sshkey`. Replace the ssh public key metadata.

### Provision the Kubernetes Cluster

```
cd terraform
terraform plan
terraform apply
```

### Increase the number of worker nodes

Edit terraform/kubestack.tf

```
resource "google_compute_instance" "kubelet" {
    count = 5
```

Increase the count to your desired instance count and apply the changes.

```
terraform plan
terraform apply
```
