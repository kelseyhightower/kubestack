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

Immutable infrastructure is the future. Instead of using cloud-init to provision machines at boot we'll create a custom image using Packer.

Run the packer commands below will create the following image:

```
kubestack-0-0-1-v20150518
```

### Create the Kubestack Base Image

```
cd packer
packer build kubestack.json
```

## Terraform

Terraform will be used to declare and provision a Kubernetes cluster.

### Prep

- Edit `terraform/terraform.tfvars`. Set valid values for `project` and `sshkey_metadata`.
- Add API tokens to `terraform/secrets/tokens.csv`. See [Kubernetes Authentication Plugins](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/authentication.md) for more details.
- Ensure your local ssh-agent is running and your ssh key has been added. This step is required by the terraform provisioner.

```
ssh-add ~/.ssh/id_rsa
```


### Provision the Kubernetes Cluster

```
cd terraform
terraform plan
terraform apply
```

### Resize the number of worker nodes

Edit `terraform/terraform.tfvars`. Set `worker_count` to the desired value:

```
worker_count = 3
```

Apply the changes:

```
terraform plan
terraform apply
```
