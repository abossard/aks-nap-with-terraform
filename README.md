
# AKS Node Auto-Provisioning (NAP) with Terraform

Deploy an Azure Kubernetes Service cluster with [Node Auto-Provisioning](https://learn.microsoft.com/azure/aks/node-autoprovision) using Terraform and the AzureRM provider.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) >= 2.60
- An Azure subscription with permissions to create AKS clusters

## Project Structure

| File | Purpose |
|------|---------|
| `providers.tf` | Terraform & AzureRM provider configuration |
| `variables.tf` | Input variables (resource group, location, cluster name, etc.) |
| `main.tf` | Core infrastructure resources (AKS cluster, NAP config) |
| `outputs.tf` | Useful outputs (cluster name, kubeconfig, etc.) |

## Getting Started

### 1. Authenticate & Set Environment Variables

```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_VAR_location="WestEurope"
export TF_VAR_resource_group_name="rg-aks-nap"
```

#### (Optional) Create the Resource Group

```bash
az group create \
  --name "$TF_VAR_resource_group_name" \
  --location "$TF_VAR_location"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Validate the Configuration

```bash
terraform validate
terraform fmt -check
```

### 4. Preview Changes

```bash
terraform plan -out=tfplan
```

### 5. Apply the Deployment

```bash
terraform apply tfplan
```

### 6. Connect to the Cluster

```bash
az aks get-credentials \
  --resource-group <RESOURCE_GROUP> \
  --name <CLUSTER_NAME>

kubectl get nodes
```

## Tear Down

```bash
terraform destroy
```

## Useful Commands

| Command | Description |
|---------|-------------|
| `terraform plan` | Dry-run — shows what will change |
| `terraform apply` | Create / update infrastructure |
| `terraform destroy` | Delete all managed resources |
| `terraform output` | Display output values |
| `terraform state list` | List resources in state |