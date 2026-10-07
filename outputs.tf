output "maintenance_assignments" {
  description = "Map of created maintenance assignments"
  value       = azurerm_maintenance_assignment_dynamic_scope.this
}

output "resource_group_name" {
  description = "Name of the resource group that holds the maintenance configurations."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "ID of the resource group that holds the maintenance configurations."
  value       = azurerm_resource_group.this.id
}

output "maintenance_configuration_ids" {
  description = "Map of maintenance configuration key to resource ID, managed and unmanaged."
  value       = local.configuration_ids
}

output "snapshot_managed_configuration_ids" {
  description = "Map of maintenance configuration key to resource ID for configurations with `snapshot_managed = true`."
  value       = { for k, v in azurerm_maintenance_configuration.snapshot_managed : k => v.id }
}
