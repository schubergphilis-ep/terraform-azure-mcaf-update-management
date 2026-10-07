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
  for_each = local.unmanaged_configurations

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
      classifications_to_include    = local.classifications[each.key].linux
      package_names_mask_to_include = each.value.install_patches.linux.package_names_mask_to_include
      package_names_mask_to_exclude = each.value.install_patches.linux.package_names_mask_to_exclude
    }

    windows {
      classifications_to_include = local.classifications[each.key].windows
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

# Same as "this", but the include lists are owned by an external snapshot process.
# lifecycle.ignore_changes cannot be conditional, hence a second resource.
resource "azurerm_maintenance_configuration" "snapshot_managed" {
  for_each = local.managed_configurations

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
      classifications_to_include    = local.classifications[each.key].linux
      package_names_mask_to_exclude = each.value.install_patches.linux.package_names_mask_to_exclude
      package_names_mask_to_include = (
        length(coalesce(each.value.install_patches.linux.package_names_mask_to_include, [])) == 0 &&
        length(local.classifications[each.key].linux) == 0
      ) ? [local.snapshot_placeholder.linux] : each.value.install_patches.linux.package_names_mask_to_include
    }

    windows {
      classifications_to_include = local.classifications[each.key].windows
      kb_numbers_to_exclude      = each.value.install_patches.windows.kb_numbers_to_exclude
      kb_numbers_to_include = (
        length(coalesce(each.value.install_patches.windows.kb_numbers_to_include, [])) == 0 &&
        length(local.classifications[each.key].windows) == 0
      ) ? [local.snapshot_placeholder.windows] : each.value.install_patches.windows.kb_numbers_to_include
    }
  }

  tags = merge(
    try(var.tags, {}),
    tomap({
      "Resource Type"               = "Maintenance Configuration"
      "aum-snapshot"                = "managed"
      "aum-snapshot-linux-extras"   = join(",", coalesce(each.value.install_patches.linux.package_names_mask_to_include, []))
      "aum-snapshot-windows-extras" = join(",", coalesce(each.value.install_patches.windows.kb_numbers_to_include, []))
    })
  )

  lifecycle {
    ignore_changes = [
      window["start_date_time"],
      install_patches[0].linux[0].package_names_mask_to_include,
      install_patches[0].windows[0].kb_numbers_to_include,
    ]
  }
}

resource "azurerm_maintenance_assignment_dynamic_scope" "this" {
  for_each = local.assignments

  name                         = each.value.name
  maintenance_configuration_id = local.configuration_ids[each.value.config_key]

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
# Classifications on a snapshot-managed configuration are installed on top of the frozen list.
# Critical or Security there installs every critical or security update, so nothing is frozen.
# The defaults for snapshot-managed configurations avoid this; the warning catches explicit overrides.
check "snapshot_managed_classifications" {
  assert {
    condition = alltrue([
      for k, v in local.managed_configurations : length(setintersection(
        toset(concat(local.classifications[k].linux, local.classifications[k].windows)),
        toset(["Critical", "Security"])
      )) == 0
    ])
    error_message = "Snapshot-managed maintenance configuration(s) ${join(", ", [for k, v in local.managed_configurations : k if length(setintersection(toset(concat(local.classifications[k].linux, local.classifications[k].windows)), toset(["Critical", "Security"]))) > 0])} include Critical or Security classifications. Those install every critical/security update on top of the frozen snapshot. Remove classifications_to_include to use the snapshot defaults ([] for Linux, [\"Definition\"] for Windows) and install only the snapshot."
  }
}
