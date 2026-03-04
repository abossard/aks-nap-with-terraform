# Copilot Instructions for AKS NAP with Terraform

## Project Overview

This repository deploys a production-grade Azure Kubernetes Service (AKS) cluster with Node Auto-Provisioning (NAP/Karpenter) using pure `azurerm` Terraform (no `azapi` provider).

## Key Conventions

- **Provider**: Only `hashicorp/azurerm` >= 4.62.1. Never introduce `azapi` or shell-based workarounds.
- **Feature toggles**: All optional features use `bool` variables prefixed with `enable_` (e.g., `enable_managed_prometheus`, `enable_app_routing`). Use `count` for conditional resources and `dynamic` blocks for conditional nested blocks on the AKS resource.
- **Naming**: Resources use `${var.project_name}` as prefix. Terraform resource names use `main` for the primary instance (e.g., `azurerm_kubernetes_cluster.main`).
- **Tags**: Every resource must include the standard tag block: `project`, `environment`, `managed_by = "terraform"`.
- **Formatting**: Always run `terraform fmt -recursive` before committing.
- **Validation**: Always run `terraform validate` after changes.

## File Structure

| File | Purpose |
|------|---------|
| `main.tf` | AKS cluster resource with all addons and feature flags |
| `monitoring.tf` | Azure Monitor Workspace, DCR/DCE pipeline, Grafana, Prometheus alerts |
| `variables.tf` | All input variables with descriptions and defaults |
| `outputs.tf` | Cluster metadata, monitoring IDs, connection commands |
| `identity.tf` | Data source for current Azure client config |
| `providers.tf` | Provider version pins |
| `terraform.tfvars` | Environment-specific overrides |

## Architecture Decisions

- **Networking**: Azure CNI Overlay with Cilium data plane and Cilium network policies (eBPF-based). Pod CIDR `10.244.0.0/16`, Service CIDR `10.0.0.0/16`.
- **Node management**: NAP (Karpenter) handles workload node pools automatically. Only a system node pool is statically defined.
- **Monitoring**: Azure Managed Prometheus via Monitor Workspace + DCR/DCE pipeline. Optional Managed Grafana.
- **Security**: Azure AD RBAC only (local accounts disabled), Workload Identity + OIDC, Azure Policy, Key Vault CSI.
- **ACNS**: Advanced Container Networking Services provides Hubble flow logs and FQDN-based network security.

## When Adding New Features

1. Add a `variable "enable_<feature>"` with `type = bool` and a sensible default in `variables.tf`.
2. Use `count` or `dynamic` blocks — never hardcode optional features.
3. Add corresponding outputs in `outputs.tf` (return `null` when disabled).
4. Add reference documentation links as comments at the top of the relevant `.tf` file.
5. Update the Feature Toggles table and Input Variables table in `README.md`.
6. Run `terraform fmt -recursive && terraform validate`.

## Reference Documentation Style

Each `.tf` file has a comment block at the top with reference links:

```hcl
# Reference Documentation:
# - Feature name:  https://link-to-docs
```

Use official sources only: `registry.terraform.io` for Terraform resources, `learn.microsoft.com` for Azure docs.

## Common Commands

```bash
terraform fmt -recursive   # Format all .tf files
terraform validate         # Validate configuration
terraform plan -out=tfplan # Preview changes
terraform apply tfplan     # Apply changes
```
