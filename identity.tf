resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.project_name}-aks-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}
