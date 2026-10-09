# snapshot_managed: separate resource, tags for the snapshot module, placeholder for empty OS blocks,
# outputs, and unmanaged configurations unchanged.

mock_provider "azurerm" {
  override_during = plan
  source          = "./tests/mocks/azurerm"
}

variables {
  resource_group_name = "test-rg"
  location            = "westeurope"
}

run "managed_and_unmanaged" {
  command = plan

  variables {
    maintenance_configurations = {
      managed = {
        snapshot_managed = true
        window           = { start_date_time = "2026-01-05 19:00", recur_every = "1Week Monday" }
        assignments      = { pg1 = { tag_values = ["patchgroup1"] } }
        install_patches = {
          linux   = { classifications_to_include = [], package_names_mask_to_include = ["datadog-agent=*"] }
          windows = { classifications_to_include = ["Definition"] }
        }
      }
      plain = {
        window      = { start_date_time = "2026-01-05 21:00", recur_every = "1Week Monday" }
        assignments = { pg2 = { tag_values = ["patchgroup2"] } }
      }
    }
  }

  assert {
    condition     = keys(azurerm_maintenance_configuration.managed) == ["managed"] && keys(azurerm_maintenance_configuration.unmanaged) == ["plain"]
    error_message = "Managed and unmanaged configurations must use separate resources."
  }
  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].tags["aum-snapshot"] == "managed"
    error_message = "Managed configuration must carry aum-snapshot = managed."
  }
  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].tags["aum-snapshot-linux-extras"] == "datadog-agent=*"
    error_message = "Linux extras tag must hold the configured include list."
  }
  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].install_patches[0].linux[0].package_names_mask_to_include == tolist(["datadog-agent=*"])
    error_message = "A non-empty include list must not get a placeholder."
  }
  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].install_patches[0].windows[0].kb_numbers_to_include == null
    error_message = "Windows has a classification, so no placeholder is needed."
  }
  assert {
    condition     = !contains(keys(azurerm_maintenance_configuration.unmanaged["plain"].tags), "aum-snapshot")
    error_message = "Unmanaged configuration must not be tagged for the snapshot."
  }
  assert {
    condition     = azurerm_maintenance_configuration.unmanaged["plain"].install_patches[0].linux[0].classifications_to_include == tolist(["Critical", "Security"])
    error_message = "Unmanaged defaults must be unchanged."
  }
  assert {
    condition     = output.resource_group_name == "test-rg" && length(output.maintenance_configuration_ids) == 2
    error_message = "Outputs are wrong."
  }
}

run "empty_os_block_gets_placeholder" {
  command = plan

  variables {
    maintenance_configurations = {
      managed = {
        snapshot_managed = true
        install_patches = {
          linux   = { classifications_to_include = [] }
          windows = { classifications_to_include = [] }
        }
      }
    }
  }

  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].install_patches[0].linux[0].package_names_mask_to_include == tolist(["aum-snapshot-placeholder=0.0.0"])
    error_message = "Empty Linux block needs the placeholder."
  }
  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].install_patches[0].windows[0].kb_numbers_to_include == tolist(["9999999"])
    error_message = "Empty Windows block needs the placeholder."
  }
  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].tags["aum-snapshot-linux-extras"] == ""
    error_message = "Placeholder must not end up in the extras tag."
  }
}

run "warns_on_explicit_critical_security" {
  command = plan

  variables {
    maintenance_configurations = {
      managed_with_override = {
        snapshot_managed = true
        install_patches  = { linux = { classifications_to_include = ["Critical", "Security"] } }
      }
    }
  }

  expect_failures = [
    check.snapshot_managed_classifications,
  ]
}

run "snapshot_defaults_for_classifications" {
  command = plan

  variables {
    maintenance_configurations = {
      managed = {
        snapshot_managed = true
        install_patches  = { linux = { package_names_mask_to_include = ["datadog-agent=*"] } }
      }
      plain = {}
    }
  }

  assert {
    condition     = length(azurerm_maintenance_configuration.managed["managed"].install_patches[0].linux[0].classifications_to_include) == 0
    error_message = "Snapshot-managed Linux must default to no classifications."
  }
  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].install_patches[0].windows[0].classifications_to_include == tolist(["Definition"])
    error_message = "Snapshot-managed Windows must default to Definition only."
  }
  assert {
    condition     = azurerm_maintenance_configuration.unmanaged["plain"].install_patches[0].windows[0].classifications_to_include == tolist(["Critical", "Security", "Definition"])
    error_message = "Unmanaged Windows default must be unchanged."
  }
  assert {
    condition     = azurerm_maintenance_configuration.unmanaged["plain"].install_patches[0].linux[0].classifications_to_include == tolist(["Critical", "Security"])
    error_message = "Unmanaged Linux default must be unchanged."
  }
}

run "no_warning_with_snapshot_defaults" {
  command = plan

  variables {
    maintenance_configurations = {
      managed = { snapshot_managed = true }
    }
  }

  assert {
    condition     = azurerm_maintenance_configuration.managed["managed"].install_patches[0].linux[0].package_names_mask_to_include == tolist(["aum-snapshot-placeholder=0.0.0"])
    error_message = "Linux default without extras needs the placeholder."
  }
}
