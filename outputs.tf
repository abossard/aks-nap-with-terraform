output "cluster_id" {
  description = "The AKS cluster resource ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity federation"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "node_resource_group" {
  description = "Auto-generated resource group containing AKS node resources"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "kubelet_identity" {
  description = "Kubelet managed identity (use for ACR pull, storage access, etc.)"
  value = {
    client_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    object_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  }
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the cluster SystemAssigned identity"
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

output "kube_config_raw" {
  description = "Raw kubeconfig (sensitive)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Raw admin kubeconfig (sensitive, only available when local accounts enabled)"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config_raw
  sensitive   = true
}

output "key_vault_secrets_provider_identity" {
  description = "Identity of the Key Vault secrets provider (use for Key Vault access policies)"
  value = {
    client_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
    object_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
  }
}

output "get_credentials_command" {
  description = "Azure CLI command to get cluster credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "portal_url" {
  description = "Azure Portal URL for the AKS cluster"
  value       = "https://portal.azure.com/#resource${azurerm_kubernetes_cluster.main.id}/overview"
}

output "current_kubernetes_version" {
  description = "The actual Kubernetes version running on the cluster"
  value       = azurerm_kubernetes_cluster.main.current_kubernetes_version
}