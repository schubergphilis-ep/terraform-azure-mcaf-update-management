locals {
  current_date    = formatdate("YYYY-MM-DD", timestamp())
  custom_time     = "22:00"
  custom_datetime = "${local.current_date} ${local.custom_time}"

  default_assignment = {
    name            = "maintenance-assignment"
    locations       = []
    os_types        = ["Windows", "Linux"]
    resource_groups = []
    resource_types  = ["Microsoft.Compute/virtualMachines"]
    tag_filter      = "Any"
    tag_name        = "patchgroup"
    tag_values      = []
  }

  # Create a flattened list of configuration-assignment pairs
  assignment_pairs = flatten([
    for config_key, config in var.maintenance_configurations : [
      for assignment_key, assignment in config.assignments : {
        config_key     = config_key
        assignment_key = assignment_key
        config_name    = config.name

        # Merge default values with provided values
        name            = assignment.name != null ? assignment.name : "${config_key}-${assignment_key}"
        locations       = assignment.locations != null ? assignment.locations : local.default_assignment.locations
        os_types        = assignment.os_types != null ? assignment.os_types : local.default_assignment.os_types
        resource_groups = assignment.resource_groups != null ? assignment.resource_groups : local.default_assignment.resource_groups
        resource_types  = assignment.resource_types != null ? assignment.resource_types : local.default_assignment.resource_types
        tag_filter      = assignment.tag_filter != null ? assignment.tag_filter : local.default_assignment.tag_filter
        tag_name        = assignment.tag_name != null ? assignment.tag_name : local.default_assignment.tag_name
        tag_values      = assignment.tag_values != null ? assignment.tag_values : local.default_assignment.tag_values
      }
    ]
  ])

  # Convert to a map with unique keys for the for_each
  assignments = {
    for pair in local.assignment_pairs :
    "${pair.config_key}-${pair.assignment_key}" => pair
  }

  # Configurations whose include lists are owned by an external snapshot process.
  managed_configurations   = { for k, v in var.maintenance_configurations : k => v if v.snapshot_managed }
  unmanaged_configurations = { for k, v in var.maintenance_configurations : k => v if !v.snapshot_managed }

  # The Maintenance API rejects an OS block without classifications and without includes.
  # Snapshot-managed configurations may start that way, so they get an include that never matches
  # until the snapshot process writes the first list.
  snapshot_placeholder = {
    linux   = "aum-snapshot-placeholder=0.0.0"
    windows = "9999999"
  }

  configuration_ids = merge(
    { for k, v in azurerm_maintenance_configuration.unmanaged : k => v.id },
    { for k, v in azurerm_maintenance_configuration.managed : k => v.id },
  )

  # Classifications are installed on top of the include list. Snapshot-managed configurations default to
  # nothing extra (Linux) and Defender platform updates only (Windows), so the frozen snapshot is all that
  # gets installed. Explicitly set values always win.
  classifications = {
    for k, v in var.maintenance_configurations : k => {
      linux = v.install_patches.linux.classifications_to_include != null ? v.install_patches.linux.classifications_to_include : (
        v.snapshot_managed ? [] : ["Critical", "Security"]
      )
      windows = v.install_patches.windows.classifications_to_include != null ? v.install_patches.windows.classifications_to_include : (
        v.snapshot_managed ? ["Definition"] : ["Critical", "Security", "Definition"]
      )
    }
  }
}
