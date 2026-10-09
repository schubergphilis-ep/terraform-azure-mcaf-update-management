# Upgrading

## v0.2 to v0.3

No action needed. The maintenance configuration resource was renamed from `this` to `unmanaged`; a `moved` block
in the module moves existing state, so the plan shows no changes.

The azurerm provider constraint is now `>= 4`. Pin the provider version in your root module.

## Enabling `snapshot_managed` on an existing configuration

Snapshot-managed configurations live in a separate resource (`managed` instead of `unmanaged`), because
`lifecycle.ignore_changes` cannot be conditional. Setting `snapshot_managed = true` on an existing configuration
therefore deletes the maintenance configuration, creates a new one, and recreates its assignments.

Either plan it outside a patch window, or move the state first so nothing is recreated:

```shell
terraform state mv \
  'module.patching.azurerm_maintenance_configuration.unmanaged["weekly1900"]' \
  'module.patching.azurerm_maintenance_configuration.managed["weekly1900"]'
```

Replace `module.patching` and `weekly1900` with your module name and configuration key. The same applies in reverse
when turning `snapshot_managed` off.
