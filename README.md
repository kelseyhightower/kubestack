# Kubestack

Provision a Kubernetes cluster with [Packer](https://packer.io) and [Terraform](https://www.terraform.io) on Google Compute Engine.

## Status

Ready for testing. Over the next couple of weeks the repo should be generic enough for reuse with complete documentation.

## Prep

- [Install Packer](https://packer.io/docs/installation.html)
- [Install Terraform](https://www.terraform.io/intro/getting-started/install.html)
- [Setup an Authentication JSON File](https://www.terraform.io/docs/providers/google/index.html#account_file)

The Packer and Terraform configs assume your authentication JSON file is stored under `/etc/kubestack-account.json`

## Packer Images

Immutable infrastructure is the future. Instead of using cloud-init to provision machines at boot we'll create a custom image using Packer.

Run the packer commands below will create the following image:

```
kubestack-0-17-1-v20150606
```

### Create the Kubestack Base Image

```
cd packer
packer build -var-file=settings.json kubestack.json
```

## Terraform

Terraform will be used to declare and provision a Kubernetes cluster.

### Prep

Generate an [etcd discovery](https://coreos.com/docs/cluster-management/setup/cluster-discovery/) token:

```
curl https://discovery.etcd.io/new?size=3
https://discovery.etcd.io/465df9c06a9d589...
```

Edit `terraform/terraform.tfvars`. Add the required values:

```
discovery_url = "https://discovery.etcd.io/465df9c06a9d589..."
project = "kubestack"
sshkey_metadata = "core: ssh-rsa AAAAB3NzaC1yc2EA..."
```

- Create your Container Engine Cluster and Add API tokens to `terraform/secrets/tokens.csv`. See [Google Container Engine](https://cloud.google.com/container-engine/docs/before-you-begin) for more details.

Example tokens.csv

```
04b6d6bfe5bexample82db624, kelseyhightower, kelseyhightower
```

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

If you run into the follow error try changing the GCE zone and try again.

```
The zone 'projects/kubestack/zones/us-central1-a' does not have enough resources available to fulfill the request.
```

```
terraform destroy
```

Get a list of GCE zones.

```
gcloud compute zones list
NAME           REGION       STATUS NEXT_MAINTENANCE TURNDOWN_DATE
asia-east1-c   asia-east1   UP
asia-east1-a   asia-east1   UP
asia-east1-b   asia-east1   UP
europe-west1-c europe-west1 UP
europe-west1-b europe-west1 UP
europe-west1-d europe-west1 UP
us-central1-a  us-central1  UP
us-central1-b  us-central1  UP
us-central1-c  us-central1  UP
us-central1-f  us-central1  UP
```

Edit `terraform.tfvars`

```
zone = "us-central1-b"
```

Be sure to generate a new etcd discovery token:

```
curl https://discovery.etcd.io/new?size=3
https://discovery.etcd.io/2e5df9c06a9d590...
```

Edit `terraform.tfvars`

```
discovery_url = "https://discovery.etcd.io/2e5df9c06a9d590..."
```

Try again.

```
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

```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

  kubernetes-api-server = https://203.0.113.158:6443
```

## Next Steps

### Configure kubectl

Replace `$kubernetes-api-server` with the terraform output. 
Replace `$token` and `$user` with the info from `terraform/secrets/tokens.csv`.

```
kubectl config set-cluster kubestack --insecure-skip-tls-verify=true --server=$kubernetes-api-server
kubectl config set-credentials kelseyhightower --token='$token'
kubectl config set-context kubestack --cluster=kubestack --user=$user
kubectl config use-context kubestack
```

```
kubectl config view
```

```
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: $kubernetes-api-server
  name: kubestack
contexts:
- context:
    cluster: kubestack
    user: $user
  name: kubestack
current-context: kubestack
kind: Config
preferences: {}
users:
- name: $user
  user:
    token: $token
```

## Register the worker nodes

Nodes will be named based on the following convention:

```
${cluster_name}-kube${count}.c.${project}.internal
```

Edit `testing-kube0.c.kubestack.internal.json`

``` 
{
  "kind": "Node",
  "apiVersion": "v1beta3",
  "metadata": {
    "name": "testing-kube0.c.kubestack.internal"
  },
  "spec": {
    "externalID": "testing-kube0.c.kubestack.internal"
  }
}
```

```
kubectl create -f testing-kube0.c.kubestack.internal.json
```
