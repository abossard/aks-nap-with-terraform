# AKS NAP Terraform Deployment Report

**Date:** 2026-03-16  
**Region:** Sweden Central  
**Subscription:** ME-MngEnvMCAP462928-anbossar-1 (`b2af20ad-98fa-4aa7-94c3-059663641d9f`)

## Summary

Full deploy → verify → destroy cycle completed successfully. All 7 resources were created, the cluster was validated as healthy, and all resources were cleanly destroyed.

## Resources Deployed (7)

| # | Resource | Name | Create Time |
|---|----------|------|-------------|
| 1 | `azurerm_resource_group` | `rg-aks-nap-26` | 22s |
| 2 | `azurerm_monitor_data_collection_endpoint` | `aks-nap-prometheus-dce` | 5s |
| 3 | `azurerm_monitor_workspace` | `aks-nap-amw` | 16s |
| 4 | `azurerm_monitor_data_collection_rule` | `aks-nap-prometheus-dcr` | 3s |
| 5 | `azurerm_kubernetes_cluster` | `aks-nap-aks` | 5m 28s |
| 6 | `azurerm_monitor_data_collection_rule_association` | `aks-nap-prometheus-dcra` | 3s |
| 7 | `azurerm_monitor_alert_prometheus_rule_group` | `aks-nap-cpu-imbalance-alerts` | 1s |

**Total apply time:** ~6 minutes

## Cluster Verification

| Check | Result |
|-------|--------|
| Kubernetes version | `1.33.7` |
| Node count | 2 (system pool, zones 1-2-3) |
| Node status | Both `Ready` |
| Node OS | Microsoft Azure Linux 3.0 (kernel 6.6.121.1) |
| Container runtime | containerd 2.0.0 |
| VM size | Standard_D4ds_v5 |
| Control plane | Reachable (`aks-nap-6fllvo8d.hcp.swedencentral.azmk8s.io`) |
| CoreDNS | Running |
| Metrics Server | Running |

## Features Enabled

- ✅ Node Auto-Provisioning (NAP/Karpenter) — mode: Auto
- ✅ Azure CNI Overlay + Cilium dataplane + Cilium network policies
- ✅ ACNS (Advanced Container Networking Services) — observability + security
- ✅ Managed Prometheus (Monitor Workspace + DCR/DCE pipeline)
- ✅ Prometheus alert rules (CPU imbalance)
- ✅ Azure AD RBAC (local accounts disabled)
- ✅ Workload Identity + OIDC
- ✅ Azure Policy
- ✅ Key Vault CSI (secret rotation every 2m)
- ✅ Web App Routing (annotation-controlled)
- ✅ Image Cleaner (48h interval)
- ✅ Storage profile (blob, disk, file, snapshot controller)
- ✅ Maintenance windows (Sunday 02:00 UTC+1)
- ✅ Cost analysis

## Destroy

All 7 resources destroyed cleanly.

| Resource | Destroy Time |
|----------|-------------|
| Prometheus rule group | < 1s |
| DCRA | < 1s |
| DCR | < 1s |
| DCE | < 1s |
| Monitor Workspace | < 1s |
| AKS Cluster | 4m 26s |
| Resource Group | 21s |

**Total destroy time:** ~5 minutes

## Provider Upgrade

| | Before | After |
|---|--------|-------|
| `azurerm` | 4.62.1 | **4.64.0** (latest) |
| Terraform | 1.14.7 | 1.14.7 |

Configuration validated successfully after upgrade (`terraform validate` + `terraform fmt`).

## Conclusion

The Terraform configuration is **production-ready**. The full lifecycle (init → plan → apply → verify → destroy) completed without errors. The provider has been upgraded to the latest version (4.64.0) and passes validation.
