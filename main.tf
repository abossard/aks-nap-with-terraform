resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.project_name

  kubernetes_version                = var.kubernetes_version
  sku_tier                          = "Standard"
  cost_analysis_enabled             = true
  local_account_disabled            = true
  role_based_access_control_enabled = true
  azure_policy_enabled              = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  image_cleaner_enabled             = true
  image_cleaner_interval_hours      = 48
  node_os_upgrade_channel           = "NodeImage"
  automatic_upgrade_channel         = "patch"

  node_provisioning_profile {
    mode               = "Auto"
    default_node_pools = "Auto"
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    node_count                   = var.system_node_count
    temporary_name_for_rotation  = "systemtmp"
    only_critical_addons_enabled = true
    os_sku                       = "AzureLinux"
    zones                        = ["1", "2", "3"]
    type                         = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge                     = "33%"
      drain_timeout_in_minutes      = 30
      node_soak_duration_in_minutes = 0
    }
  }

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
    }
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.aks_admin_group_ids
  }

  identity {
    type = "SystemAssigned"
  }

  workload_autoscaler_profile {
    keda_enabled                    = false
    vertical_pod_autoscaler_enabled = false
  }

  storage_profile {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  web_app_routing {
    dns_zone_ids = []
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+01:00"
    duration    = 4
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+01:00"
    duration    = 4
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}