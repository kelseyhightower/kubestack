# Kubestack

Provision a Kubernetes cluster with [Packer](https://packer.io) and [Terraform](https://www.terraform.io).

## Packer Images

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

```
cd terraform
```

```
terraform plan
```

```
terraform apply
```
