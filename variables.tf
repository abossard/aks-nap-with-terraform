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
