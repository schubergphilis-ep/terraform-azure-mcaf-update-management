terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4, < 6"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

# azurerm 5.0 no longer registers resource providers by default; register only what this needs.
# Works the same on azurerm 4.x.
provider "azurerm" {
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.Maintenance", "Microsoft.Logic", "Microsoft.Insights"]
  features {}
}

data "azurerm_client_config" "current" {}

# Weekly patch groups, Linux and Windows mixed, with the include lists handed to the snapshot.
# snapshot_managed = true also defaults the classifications to [] (Linux) and ["Definition"] (Windows),
# so only the snapshot, Defender platform updates and the Datadog agent are installed.
module "updates" {
  source = "../../"

  resource_group_name = "rg-update-management"
  location            = "westeurope"

  maintenance_configurations = {
    weekly1900 = {
      name             = "weekly-maintenance-1900"
      snapshot_managed = true
      window           = { start_date_time = "2026-01-05 19:00", recur_every = "1Week Monday" }
      assignments      = { patchgroup1 = { tag_values = ["patchgroup1"] } }
      install_patches  = { linux = { package_names_mask_to_include = ["datadog-agent=*"] } }
    }
    weekly2100 = {
      name             = "weekly-maintenance-2100"
      snapshot_managed = true
      window           = { start_date_time = "2026-01-05 21:00", recur_every = "1Week Monday" }
      assignments      = { patchgroup2 = { tag_values = ["patchgroup2"] } }
      install_patches  = { linux = { package_names_mask_to_include = ["datadog-agent=*"] } }
    }
  }
}

# Freezes the pending updates every Monday 07:00 and writes them into both configurations.
module "update_snapshot" {
  source = "github.com/schubergphilis-ep/terraform-azure-mcaf-update-management-snapshot"

  resource_group_name = module.updates.resource_group_name
  subscription_ids    = [data.azurerm_client_config.current.subscription_id]
}
