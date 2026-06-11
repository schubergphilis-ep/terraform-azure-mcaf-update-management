variable "resource_group_name" {
  description = "The name of the resource group where the maintenance configuration will be created."
  type        = string
}

variable "location" {
  description = "The location where the maintenance configuration will be created."
  type        = string
}

variable "maintenance_configurations" {
  type = map(object({
    name                     = optional(string)
    scope                    = optional(string, "InGuestPatch")
    in_guest_user_patch_mode = optional(string, "User")
    window = optional(object({
      start_date_time = optional(string)
      duration        = optional(string)
      time_zone       = optional(string, "W. Europe Standard Time")
      recur_every     = optional(string, "1Weeks")
    }), {})
    install_patches = optional(object({
      reboot = optional(string, "IfRequired")
      linux = optional(object({
        classifications_to_include    = optional(list(string), ["Critical", "Security"])
        package_names_mask_to_exclude = optional(list(string))
        package_names_mask_to_include = optional(list(string))
      }), {})
      windows = optional(object({
        classifications_to_include = optional(list(string), ["Critical", "Security", "Definition"])
        kb_numbers_to_exclude      = optional(list(string))
        kb_numbers_to_include      = optional(list(string))
      }), {})
    }), {}),
    assignments = optional(map(object({
      name            = optional(string)
      locations       = optional(list(string))
      os_types        = optional(list(string))
      resource_groups = optional(list(string))
      resource_types  = optional(list(string))
      tag_filter      = optional(string)
      tag_name        = optional(string)
      tag_values      = optional(list(string))
    })), {})
  }))
  default = {
    weekly1900 = {
      name = "weekly-maintenance-1900"
      window = {
        start_date_time = "2025-01-01 19:00"
      }
      assignments = {
        patchgroup1 = {
          tag_values = ["patchgroup1"]
        }
      }
    }
    weekly2100 = {
      name = "weekly-maintenance-2100"
      window = {
        start_date_time = "2025-01-01 21:00"
      }
      assignments = {
        patchgroup2 = {
          tag_values = ["patchgroup2"]
        }
      }
    }
    weekly2300 = {
      name = "weekly-maintenance-2300"
      window = {
        start_date_time = "2025-01-01 23:00"
      }
      assignments = {
        patchgroup3 = {
          tag_values = ["patchgroup3"]
        }
      }
    }
  }
  description = <<DESCRIPTION
A map of objects containing the configuration for the maintenance configurations to be created.

- `name` - (Required) The name of the maintenance configuration.
- `scope` - (Required) The scope of the maintenance configuration.
- `in_guest_user_patch_mode` - (Required) The in-guest user patch mode of the maintenance configuration.
- `window` - (Required) The window block as defined below.
  `start_date_time` - (Optional) The start date time of the maintenance window.
  `duration` - (Optional) The duration of the maintenance window in HH:mm format.
  `time_zone` - (Optional) The time zone of the maintenance window.
  `recur_every` - (Optional) The recurrence of the maintenance window.
- `install_patches` - (Required) The install_patches block as defined below.
  `reboot` - (Optional) The reboot of the install patches.
  `linux` - (Optional) The linux block as defined below.
    `classifications_to_include` - (Optional) List of Classification category of patches to be patched. Possible values are Critical, Security and Other.
    `package_names_mask_to_exclude` - (Optional) List of package names to be excluded from patching.
    `package_names_mask_to_include` - (Optional) List of package names to be included for patching.
  `windows` - (Optional) The windows block as defined below.
    `classifications_to_include` - (Optional) List of Classification category of patches to be patched. Possible values are Critical, Security, UpdateRollup, FeaturePack, ServicePack, Definition, Tools and Updates.
    `kb_numbers_to_exclude` - (Optional) List of KB numbers to be excluded from patching.
    `kb_numbers_to_include` - (Optional) List of KB numbers to be included for patching.
- `assignments` - (Optional) A map of objects containing the configuration for the maintenance assignments to be created.
```
maintenance_configurations = {
  "weekly1900" = {
    name = "weekly-maintenance-1900"
    window = {
      start_date_time = "2025-01-01 19:00"
      time_zone       = "W. Europe Standard Time"
      recur_every     = "1Days"
    }
    install_patches = {
      reboot = "IfRequired"
      windows = {
        classifications_to_include = ["Definition"]
      }
    }
    assignments = {
      "patchgroup1" = {
        name            = "patchgroup1-1900"
        locations       = ["germanywestcentral", "westeurope"]
        os_types        = ["Windows"]
        resource_groups = ["resource-group-name"]
        tag_name        = "patchgroup"
        tag_values      = ["patchgroup1"]
      }
    }
  }
}

```
DESCRIPTION
}

variable "tags" {
  description = "A mapping of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
