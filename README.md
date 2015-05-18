# Kubestack

Provision a Kubernetes cluster with [Packer](https://packer.io) and [Terraform](https://www.terraform.io).

## Packer Images

Immutable infrastructure is the future. Instead of using cloud-init to provision machines at boot we'll create custom images using Packer for the Kubernetes server and worker machines.

```
cd packer
```

### Kubestack Base Image

```
packer build kubestack.json
```

### Kubestack Server Image

```
packer build kubestack-server.json
```

### Kubestack Worker Image

```
packer build kubestack-worker.json
```

## Terraform

Terraform will be used to declare and provision a Kubernetes cluster.

```
cd terraform
```

```
terraform plan
```

```
terraform apply
```

### Increase the number of worker nodes

Edit terraform/kubestack.tf

```
resource "google_compute_instance" "kubelet" {
    count = 5
```

Increase the count to your desired instance count.

```
terraform plan
terraform apply
```
