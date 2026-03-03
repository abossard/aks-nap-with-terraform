# AKS Cluster Configuration Values — Pure AzureRM (No AZAPI)

> **Provider**: `hashicorp/azurerm` >= `4.62.1` (API: `Microsoft.ContainerService/2025-07-01`)
>
> **Goal**: AKS with Node Auto-Provisioning (NAP/Karpenter), Azure CNI powered by Cilium, Azure RBAC, adapted for the BIMS workload from `.temp/AKS_CLUSTER_ANALYSIS.md`.

---

## 1. Provider Requirement

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.62"
    }
  }
}
```

No `azapi` provider needed — `node_provisioning_profile` is natively supported in v4.62+.

---

## 2. Cluster-Level Settings

| Attribute | Value | Rationale |
|---|---|---|
| `name` | `"${var.project_name}-aks"` | Naming convention |
| `location` | `var.location` | From `terraform.tfvars` (`WestEurope`) |
| `resource_group_name` | `azurerm_resource_group.main.name` | Managed by Terraform |
| `dns_prefix` | `var.project_name` | e.g. `aks-nap` |
| `kubernetes_version` | `"1.31"` | Latest stable; NAP requires >= 1.26 |
| `sku_tier` | `"Standard"` | SLA-backed uptime; required for `cost_analysis_enabled` |
| `cost_analysis_enabled` | `true` | Visibility in Azure portal |
| `local_account_disabled` | `true` | Security: force Azure AD auth only |
| `role_based_access_control_enabled` | `true` | Default, explicitly set |
| `azure_policy_enabled` | `true` | Policy enforcement |
| `oidc_issuer_enabled` | `true` | Required for workload identity |
| `workload_identity_enabled` | `true` | Modern pod identity (replaces pod-managed identity) |
| `image_cleaner_enabled` | `true` | Automatic cleanup of stale images |
| `image_cleaner_interval_hours` | `48` | Cleanup every 2 days |
| `node_os_upgrade_channel` | `"NodeImage"` | Auto-update node OS images |
| `automatic_upgrade_channel` | `"patch"` | Stable channel auto-upgrades |

---

## 3. Node Provisioning Profile (NAP — Karpenter)

```hcl
node_provisioning_profile {
  mode               = "Auto"     # Enables Node Auto-Provisioning (Karpenter)
  default_node_pools = "Auto"     # NAP manages default node pools automatically
}
```

| Attribute | Value | Notes |
|---|---|---|
| `mode` | `"Auto"` | Enables NAP — AKS dynamically provisions right-sized VMs |
| `default_node_pools` | `"Auto"` | NAP auto-creates/manages default NodePools via Karpenter CRDs |

**Key implications of NAP**:
- NAP automatically selects VM sizes based on pending pod requirements
- Creates `system-surge` node pools for system pod demand spikes
- User workload node pools are created/destroyed dynamically
- At least one system node pool (`default_node_pool`) must still be defined in Terraform
- Further tuning is done via Kubernetes CRDs (`NodePool`, `AKSNodeClass`) post-deployment

---

## 4. Default Node Pool (System Pool)

The system node pool runs critical system pods. NAP manages additional workload pools.

```hcl
default_node_pool {
  name                        = "system"
  vm_size                     = "Standard_D4ds_v5"
  node_count                  = 2
  temporary_name_for_rotation = "systemtmp"
  only_critical_addons_enabled = true
  os_sku                      = "AzureLinux"
  zones                       = ["1", "2", "3"]
  type                        = "VirtualMachineScaleSets"

  upgrade_settings {
    max_surge                     = "33%"
    drain_timeout_in_minutes      = 30
    node_soak_duration_in_minutes = 0
  }
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `name` | `"system"` | System node pool for critical addons |
| `vm_size` | `"Standard_D4ds_v5"` | 4 vCPU / 16 GB — sufficient for system pods |
| `node_count` | `2` | Minimum HA across zones |
| `temporary_name_for_rotation` | `"systemtmp"` | Required for in-place `vm_size` changes |
| `only_critical_addons_enabled` | `true` | Taints pool with `CriticalAddonsOnly=true:NoSchedule`; keeps workloads off system pool |
| `os_sku` | `"AzureLinux"` | Microsoft's container-optimized Linux (smaller, faster boot) |
| `zones` | `["1", "2", "3"]` | Zone-redundant for HA |
| `type` | `"VirtualMachineScaleSets"` | Required for multi-pool + NAP |
| `max_surge` | `"33%"` | Upgrade speed vs disruption balance |

---

## 5. Network Profile — Azure CNI + Cilium Overlay

```hcl
network_profile {
  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  network_data_plane  = "cilium"
  network_policy      = "cilium"
  load_balancer_sku   = "standard"
  outbound_type       = "loadBalancer"
  pod_cidr            = "10.244.0.0/16"
  service_cidr        = "10.0.0.0/16"
  dns_service_ip      = "10.0.0.10"

  load_balancer_profile {
    managed_outbound_ip_count = 1
    idle_timeout_in_minutes   = 30
  }

  advanced_networking {
    observability_enabled = true
    security_enabled      = true
  }
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `network_plugin` | `"azure"` | Azure CNI — required for Cilium |
| `network_plugin_mode` | `"overlay"` | Overlay mode — pods get IPs from separate overlay CIDR, not VNET subnet; maximizes pod density |
| `network_data_plane` | `"cilium"` | eBPF-powered data plane; replaces kube-proxy & iptables |
| `network_policy` | `"cilium"` | Cilium-native network policies (L3/L4/L7) — must match `network_data_plane` |
| `load_balancer_sku` | `"standard"` | Required for production; supports zones + NAT |
| `outbound_type` | `"loadBalancer"` | Default egress via Azure LB |
| `pod_cidr` | `"10.244.0.0/16"` | Overlay pod address space (~65k pods) |
| `service_cidr` | `"10.0.0.0/16"` | Kubernetes service ClusterIP range |
| `dns_service_ip` | `"10.0.0.10"` | Must be within `service_cidr` |
| `observability_enabled` | `true` | Cilium Hubble-powered flow observability |
| `security_enabled` | `true` | Cilium advanced security features (FQDN policies, etc.) |

**Why Cilium?**
- eBPF replaces iptables → lower latency, better scale
- Native network policy support (L3/L4/L7)
- Built-in observability via Hubble
- Required for advanced networking features
- No Windows node support (acceptable — BIMS workloads are Linux)

---

## 6. Azure AD RBAC Integration

```hcl
azure_active_directory_role_based_access_control {
  azure_rbac_enabled     = true
  admin_group_object_ids = var.aks_admin_group_ids
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `azure_rbac_enabled` | `true` | Azure RBAC for K8s authorization — manage access via Azure role assignments |
| `admin_group_object_ids` | `var.aks_admin_group_ids` | Azure AD groups with cluster admin access |

Combined with `local_account_disabled = true`, all auth flows through Azure AD.

---

## 7. Identity

```hcl
identity {
  type = "SystemAssigned"
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `type` | `"SystemAssigned"` | Simplest; Azure auto-manages the identity lifecycle. Switch to `UserAssigned` if you need cross-resource pre-assignment. |

---

## 8. Workload Autoscaler Profile

```hcl
workload_autoscaler_profile {
  keda_enabled                    = false
  vertical_pod_autoscaler_enabled = false
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `keda_enabled` | `false` | Event-driven autoscaling (scale on queue depth, custom metrics) |
| `vertical_pod_autoscaler_enabled` | `false` | Auto-tune pod CPU/memory requests |

---

## 9. Storage Profile

Adapted from BIMS analysis: workloads use Azure Files (RWX) and Azure Disks (RWO).

```hcl
storage_profile {
  blob_driver_enabled         = true
  disk_driver_enabled         = true
  file_driver_enabled         = true
  snapshot_controller_enabled = true
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `blob_driver_enabled` | `true` | Azure Blob CSI — for large unstructured data |
| `disk_driver_enabled` | `true` | Azure Disk CSI — for StatefulSets (PostgreSQL, RabbitMQ, OpenSearch from BIMS analysis) |
| `file_driver_enabled` | `true` | Azure File CSI — for RWX shared volumes (config, license, logs from BIMS analysis) |
| `snapshot_controller_enabled` | `true` | PV snapshots for backup/restore |

---

## 10. Key Vault Secrets Provider

```hcl
key_vault_secrets_provider {
  secret_rotation_enabled  = true
  secret_rotation_interval = "2m"
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `secret_rotation_enabled` | `true` | Auto-sync secrets from Key Vault |
| `secret_rotation_interval` | `"2m"` | Poll every 2 minutes |

---

## 11. Monitoring & Observability

```hcl
monitor_metrics {
  annotations_allowed = null
  labels_allowed      = null
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `annotations_allowed` | `null` | Managed Prometheus — required block if using Azure Monitor |
| `labels_allowed` | `null` | Can specify comma-separated K8s label keys for metrics later |

**Namespace filtering**: Only the `default` namespace should be monitored. Apply the following `ama-metrics-settings-configmap` post-deployment:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ama-metrics-settings-configmap
  namespace: kube-system
data:
  schema-version: v1
  config-version: ver1
  default-targets-metrics-keep-list: ""
  default-targets-scrape-interval-seconds: "30"
  monitor_kubernetes_pods: "true"
  monitor_kubernetes_pods_namespaces: "default"
```

---

## 12. Maintenance Windows

```hcl
maintenance_window_auto_upgrade {
  frequency  = "Weekly"
  interval   = 1
  day_of_week = "Sunday"
  start_time  = "02:00"
  utc_offset  = "+01:00"
  duration    = 4
}

maintenance_window_node_os {
  frequency  = "Weekly"
  interval   = 1
  day_of_week = "Sunday"
  start_time  = "02:00"
  utc_offset  = "+01:00"
  duration    = 4
}
```

| Attribute | Value | Rationale |
|---|---|---|
| `frequency` | `"Weekly"` | Predictable schedule |
| `day_of_week` | `"Sunday"` | Lowest impact window |
| `start_time` | `"02:00"` | Aligns with existing BIMS cron jobs at 2 AM |
| `utc_offset` | `"+01:00"` | CET (West Europe) |
| `duration` | `4` | 4-hour maintenance window |

---

## 13. Tags

```hcl
tags = {
  project     = var.project_name
  environment = var.environment
  managed_by  = "terraform"
}
```

---

## 14. Required Variables Summary

| Variable | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | `"aks-nap"` | Project identifier |
| `location` | `string` | `"WestEurope"` | Azure region |
| `resource_group_name` | `string` | `""` | RG name (auto-generated if empty) |
| `environment` | `string` | `"production"` | Environment tag |
| `kubernetes_version` | `string` | `"1.31"` | K8s version |
| `aks_admin_group_ids` | `list(string)` | `[]` | Azure AD group Object IDs for cluster admin |
| `system_node_vm_size` | `string` | `"Standard_D4ds_v5"` | System pool VM SKU |
| `system_node_count` | `number` | `2` | System pool node count |

