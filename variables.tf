variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "WestEurope"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
default     = ""    
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "enable_local_accounts" {
  description = "Enable local accounts on AKS (set true for testing, false for production)"
  type        = bool
  default     = false
}

variable "auto_calculated_salt" {
  description = "Auto-calculated SALT value"
  type        = string
  default     = ""
}
