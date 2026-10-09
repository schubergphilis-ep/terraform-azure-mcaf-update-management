# Shared mock defaults for the azurerm provider, so mocked values pass resource ID validation.

mock_resource "azurerm_resource_group" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  }
}

mock_resource "azurerm_maintenance_configuration" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Maintenance/maintenanceConfigurations/test"
  }
}
