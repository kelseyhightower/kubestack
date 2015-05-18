# Kubestack

Provision a Kubernetes cluster with [Packer](https://packer.io) and [Terraform](https://www.terraform.io).

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
