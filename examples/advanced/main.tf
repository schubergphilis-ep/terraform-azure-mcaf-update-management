terraform {
  required_version = ">= 1.9"
}

module "updates" {
  source = "../../"

  resource_group_name = "resource-group-name"
  location            = "germanywestcentral"

  maintenance_configurations = {
    "weekly1900" = {
      name = "weekly-maintenance-1900"
      window = {
        start_date_time = "2025-01-01 19:00"
        duration        = "04:00"
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
    },
    "weekly2100" = {
      name = "weekly-maintenance-2100"
      window = {
        start_date_time = "2025-01-01 21:00"
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
        "patchgroup2" = {
          name            = "patchgroup1-2100"
          locations       = ["germanywestcentral", "westeurope"]
          os_types        = ["Windows"]
          resource_groups = ["resource-group-name"]
          tag_name        = "patchgroup"
          tag_values      = ["patchgroup2"]
        }
      }
    },
    "weekly2300" = {
      name = "weekly-maintenance-2300"
      window = {
        start_date_time = "2025-01-01 23:00"
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
        "patchgroup3" = {
          name            = "patchgroup3-2300"
          locations       = ["germanywestcentral", "westeurope"]
          os_types        = ["Windows"]
          resource_groups = ["resource-group-name"]
          tag_name        = "patchgroup"
          tag_values      = ["patchgroup3"]
        }
      }
    }
  }

  tags = {
    environment = "production"
    deployment  = "terraform"
  }
}