# Reference Documentation:
# - Azure Managed Prometheus:       https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/prometheus-metrics-overview
# - azurerm_monitor_workspace:      https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_workspace
# - azurerm_dashboard_grafana:      https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dashboard_grafana
# - azurerm_monitor_data_collection_rule: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule
# - ACNS observability:             https://learn.microsoft.com/en-us/azure/aks/use-advanced-container-networking-services

# Azure Monitor Workspace for Managed Prometheus
resource "azurerm_monitor_workspace" "prometheus" {
  count               = var.enable_managed_prometheus ? 1 : 0
  name                = "${var.project_name}-amw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Azure Managed Grafana for dashboards (Prometheus + ACNS flow logs)
resource "azurerm_dashboard_grafana" "main" {
  count                             = var.enable_managed_grafana ? 1 : 0
  name                              = "${var.project_name}-grafana"
  resource_group_name               = azurerm_resource_group.main.name
  location                          = azurerm_resource_group.main.location
  grafana_major_version             = 11
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus[0].id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Grant Grafana identity "Monitoring Reader" on the Monitor Workspace
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  count                = var.enable_managed_grafana ? 1 : 0
  scope                = azurerm_monitor_workspace.prometheus[0].id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.main[0].identity[0].principal_id
}

# Grant Grafana identity "Monitoring Data Reader" on the subscription for querying metrics
resource "azurerm_role_assignment" "grafana_monitoring_data_reader" {
  count                = var.enable_managed_grafana ? 1 : 0
  scope                = azurerm_monitor_workspace.prometheus[0].id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.main[0].identity[0].principal_id
}

# Data Collection Endpoint
resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  count                         = var.enable_managed_prometheus ? 1 : 0
  name                          = "${var.project_name}-prometheus-dce"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  kind                          = "Linux"
  public_network_access_enabled = true

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Data Collection Rule for Prometheus metrics
resource "azurerm_monitor_data_collection_rule" "prometheus" {
  count                       = var.enable_managed_prometheus ? 1 : 0
  name                        = "${var.project_name}-prometheus-dcr"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus[0].id
  kind                        = "Linux"

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus[0].id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Associate DCR with AKS cluster
resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  count                   = var.enable_managed_prometheus ? 1 : 0
  name                    = "${var.project_name}-prometheus-dcra"
  target_resource_id      = azurerm_kubernetes_cluster.main.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus[0].id
}

# Prometheus Alert: Node CPU Imbalance
# Fires when any node's avg CPU over 5min is >20% above the cluster-wide node average
resource "azurerm_monitor_alert_prometheus_rule_group" "cpu_imbalance" {
  count               = var.enable_managed_prometheus ? 1 : 0
  name                = "${var.project_name}-cpu-imbalance-alerts"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  cluster_name        = azurerm_kubernetes_cluster.main.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.prometheus[0].id]

  rule {
    alert      = "NodeCPUImbalance"
    enabled    = true
    expression = <<-PROMQL
      (
        1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))
      )
      >
      (
        avg(1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) * 1.2
      )
    PROMQL
    for        = "PT5M"
    severity   = 3

    annotations = {
      summary     = "Node {{ $labels.instance }} CPU is >20% above cluster average"
      description = "Node {{ $labels.instance }} has significantly higher CPU usage than the cluster mean over the last 5 minutes."
    }

    labels = {
      severity = "warning"
      team     = "platform"
    }
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
