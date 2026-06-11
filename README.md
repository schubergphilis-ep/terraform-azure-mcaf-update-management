# Maintenance Window Recurrence

You can define the frequency at which a maintenance window recurs using daily, weekly, or monthly schedules. Here’s how to format each schedule type:

# Description

With this module you can setup scheduled patching for your azure vms.
this does require you to have your vm's on the Patch orchestration of "Customer Managed Schedules"
you can set this on the vm's if you use the SBP module with the following properties.

```terraform
  patch_mode                                             = "AutomaticByPlatform"
  bypass_platform_safety_checks_on_user_schedule_enabled = true
```

## Daily Schedule
- **Format**: `recur_every: [Frequency as integer]['Day(s)']`
- If no frequency is provided, it defaults to 1.
- **Examples**:
  - `recur_every: Day` (recurs every day)
  - `recur_every: 3Days` (recurs every 3 days)

## Weekly Schedule
- **Format**: `recur_every: [Frequency as integer]['Week(s)'] [Optional: comma-separated list of weekdays (e.g., Monday-Sunday)]`
- **Examples**:
  - `recur_every: 3Weeks` (recurs every 3 weeks)
  - `recur_every: Week Saturday,Sunday` (recurs every week on Saturday and Sunday)
  - `recur_every: 1Week Monday` (recurs every week on monday)

## Monthly Schedule
- **Two possible formats**:
  1. `recur_every: [Frequency as integer]['Month(s)'] [Comma-separated list of month days]`
  2. `recur_every: [Frequency as integer]['Month(s)'] [Week of Month (First, Second, Third, Fourth, Last)] [Weekday (e.g., Monday-Sunday)] [Optional Offset (Number of days)]`

- The offset value must be between -6 and 6, inclusive.

- **Examples**:
  - `recur_every: Month` (recurs every month)
  - `recur_every: 2Months` (recurs every 2 months)
  - `recur_every: Month day23,day24` (recurs monthly on the 23rd and 24th)
  - `recur_every: Month Last Sunday` (recurs on the last Sunday of every month)
  - `recur_every: Month Fourth Monday` (recurs on the fourth Monday of every month)
  - `recur_every: Month Last Sunday Offset-3` (recurs on the Sunday before the last Sunday of every month)
  - `recur_every: Month Third Sunday Offset6` (recurs 6 days after the third Sunday of every month)


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_maintenance_assignment_dynamic_scope.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/maintenance_assignment_dynamic_scope) | resource |
| [azurerm_maintenance_configuration.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/maintenance_configuration) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | The location where the maintenance configuration will be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group where the maintenance configuration will be created. | `string` | n/a | yes |
| <a name="input_maintenance_configurations"></a> [maintenance\_configurations](#input\_maintenance\_configurations) | A map of objects containing the configuration for the maintenance configurations to be created.<br/><br/>- `name` - (Required) The name of the maintenance configuration.<br/>- `scope` - (Required) The scope of the maintenance configuration.<br/>- `in_guest_user_patch_mode` - (Required) The in-guest user patch mode of the maintenance configuration.<br/>- `window` - (Required) The window block as defined below.<br/>  `start_date_time` - (Optional) The start date time of the maintenance window.<br/>  `time_zone` - (Optional) The time zone of the maintenance window.<br/>  `recur_every` - (Optional) The recurrence of the maintenance window.<br/>- `install_patches` - (Required) The install\_patches block as defined below.<br/>  `reboot` - (Optional) The reboot of the install patches.<br/>  `linux` - (Optional) The linux block as defined below.<br/>    `classifications_to_include` - (Optional) List of Classification category of patches to be patched. Possible values are Critical, Security and Other.<br/>    `package_names_mask_to_exclude` - (Optional) List of package names to be excluded from patching.<br/>    `package_names_mask_to_include` - (Optional) List of package names to be included for patching.<br/>  `windows` - (Optional) The windows block as defined below.<br/>    `classifications_to_include` - (Optional) List of Classification category of patches to be patched. Possible values are Critical, Security, UpdateRollup, FeaturePack, ServicePack, Definition, Tools and Updates.<br/>    `kb_numbers_to_exclude` - (Optional) List of KB numbers to be excluded from patching.<br/>    `kb_numbers_to_include` - (Optional) List of KB numbers to be included for patching.<br/>- `assignments` - (Optional) A map of objects containing the configuration for the maintenance assignments to be created.<pre>maintenance_configurations = {<br/>  "weekly1900" = {<br/>    name = "weekly-maintenance-1900"<br/>    window = {<br/>      start_date_time = "2025-01-01 19:00"<br/>      time_zone       = "W. Europe Standard Time"<br/>      recur_every     = "1Days"<br/>    }<br/>    install_patches = {<br/>      reboot = "IfRequired"<br/>      windows = {<br/>        classifications_to_include = ["Definition"]<br/>      }<br/>    }<br/>    assignments = {<br/>      "patchgroup1" = {<br/>        name            = "patchgroup1-1900"<br/>        locations       = ["germanywestcentral", "westeurope"]<br/>        os_types        = ["Windows"]<br/>        resource_groups = ["resource-group-name"]<br/>        tag_name        = "patchgroup"<br/>        tag_values      = ["patchgroup1"]<br/>      }<br/>    }<br/>  }<br/>}</pre> | <pre>map(object({<br/>    name                     = optional(string)<br/>    scope                    = optional(string, "InGuestPatch")<br/>    in_guest_user_patch_mode = optional(string, "User")<br/>    window = optional(object({<br/>      start_date_time = optional(string)<br/>      time_zone       = optional(string, "W. Europe Standard Time")<br/>      recur_every     = optional(string, "1Weeks")<br/>    }), {})<br/>    install_patches = optional(object({<br/>      reboot = optional(string, "IfRequired")<br/>      linux = optional(object({<br/>        classifications_to_include    = optional(list(string), ["Critical", "Security"])<br/>        package_names_mask_to_exclude = optional(list(string))<br/>        package_names_mask_to_include = optional(list(string))<br/>      }), {})<br/>      windows = optional(object({<br/>        classifications_to_include = optional(list(string), ["Critical", "Security", "Definition"])<br/>        kb_numbers_to_exclude      = optional(list(string))<br/>        kb_numbers_to_include      = optional(list(string))<br/>      }), {})<br/>    }), {}),<br/>    assignments = optional(map(object({<br/>      name            = optional(string)<br/>      locations       = optional(list(string))<br/>      os_types        = optional(list(string))<br/>      resource_groups = optional(list(string))<br/>      resource_types  = optional(list(string))<br/>      tag_filter      = optional(string)<br/>      tag_name        = optional(string)<br/>      tag_values      = optional(list(string))<br/>    })), {})<br/>  }))</pre> | <pre>{<br/>  "weekly1900": {<br/>    "assignments": {<br/>      "patchgroup1": {<br/>        "tag_values": [<br/>          "patchgroup1"<br/>        ]<br/>      }<br/>    },<br/>    "name": "weekly-maintenance-1900",<br/>    "window": {<br/>      "start_date_time": "2025-01-01 19:00"<br/>    }<br/>  },<br/>  "weekly2100": {<br/>    "assignments": {<br/>      "patchgroup2": {<br/>        "tag_values": [<br/>          "patchgroup2"<br/>        ]<br/>      }<br/>    },<br/>    "name": "weekly-maintenance-2100",<br/>    "window": {<br/>      "start_date_time": "2025-01-01 21:00"<br/>    }<br/>  },<br/>  "weekly2300": {<br/>    "assignments": {<br/>      "patchgroup3": {<br/>        "tag_values": [<br/>          "patchgroup3"<br/>        ]<br/>      }<br/>    },<br/>    "name": "weekly-maintenance-2300",<br/>    "window": {<br/>      "start_date_time": "2025-01-01 23:00"<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_maintenance_assignments"></a> [maintenance\_assignments](#output\_maintenance\_assignments) | Map of created maintenance assignments |
<!-- END_TF_DOCS -->

**Issues**

If required only working version for reboot:

https://github.com/hashicorp/terraform-provider-azurerm/issues/20684


## License

**Copyright:** Schuberg Philis

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```