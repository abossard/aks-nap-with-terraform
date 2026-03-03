variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "WestEurope"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "aks-nap"
}

variable "environment" {
  description = "Environment tag (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "kubernetes_version" {
  description = "Kubernetes version (minor alias e.g. 1.31)"
  type        = string
  default     = "1.33"
}

variable "aks_admin_group_ids" {
  description = "Azure AD group Object IDs for AKS cluster admin role"
  type        = list(string)
  default     = []
}

variable "system_node_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_D4ds_v5"
}

variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 2
}

variable "private_cluster_enabled" {
  description = "Enable private cluster (API server accessible only via private IP, forces new resource)"
  type        = bool
  default     = false
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Enable public FQDN for private cluster (only relevant when private_cluster_enabled is true)"
  type        = bool
  default     = false
}

variable "api_server_vnet_integration_enabled" {
  description = "Enable API server VNet integration (requires api_server_subnet_id when true)"
  type        = bool
  default     = false
}

variable "api_server_subnet_id" {
  description = "Subnet ID for API server VNet integration (required when api_server_vnet_integration_enabled is true)"
  type        = string
  default     = null
}

variable "enable_managed_prometheus" {
  description = "Enable Azure Managed Prometheus (Monitor Workspace, DCR, Grafana, and metrics collection)"
  type        = bool
  default     = true
}

variable "enable_managed_grafana" {
  description = "Enable Azure Managed Grafana for dashboards (requires enable_managed_prometheus)"
  type        = bool
  default     = false
}

variable "enable_acns_observability" {
  description = "Enable Advanced Container Networking Services (ACNS) with Hubble-compatible observability and flow logs"
  type        = bool
  default     = true
}
