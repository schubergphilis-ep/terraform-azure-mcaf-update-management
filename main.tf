resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(
    try(var.tags, {}),
    tomap({
      "Resource Type" = "Resource Group"
    })
  )
}

resource "azurerm_maintenance_configuration" "this" {
  for_each = var.maintenance_configurations

  name                     = each.value.name == null ? each.key : each.value.name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  scope                    = each.value.scope
  in_guest_user_patch_mode = each.value.in_guest_user_patch_mode

  window {
    start_date_time = each.value.window.start_date_time == null ? local.custom_datetime : each.value.window.start_date_time
    duration        = each.value.window.duration
    time_zone       = each.value.window.time_zone
    recur_every     = each.value.window.recur_every
  }

  install_patches {
    reboot = each.value.install_patches.reboot

    linux {
      classifications_to_include    = each.value.install_patches.linux.classifications_to_include
      package_names_mask_to_include = each.value.install_patches.linux.package_names_mask_to_include
      package_names_mask_to_exclude = each.value.install_patches.linux.package_names_mask_to_exclude
    }

    windows {
      classifications_to_include = each.value.install_patches.windows.classifications_to_include
      kb_numbers_to_include      = each.value.install_patches.windows.kb_numbers_to_include
      kb_numbers_to_exclude      = each.value.install_patches.windows.kb_numbers_to_exclude
    }
  }

  tags = merge(
    try(var.tags, {}),
    tomap({
      "Resource Type" = "Maintenance Configuration"
    })
  )

  lifecycle {
    ignore_changes = [
      window["start_date_time"]
    ]
  }
}

resource "azurerm_maintenance_assignment_dynamic_scope" "this" {
  for_each = local.assignments

  name                         = each.value.name
  maintenance_configuration_id = azurerm_maintenance_configuration.this[each.value.config_key].id

  filter {
    locations       = each.value.locations
    os_types        = each.value.os_types
    resource_groups = each.value.resource_groups
    resource_types  = each.value.resource_types
    tag_filter      = each.value.tag_filter

    tags {
      tag    = each.value.tag_name
      values = each.value.tag_values
    }
  }
}