output "tfstate_storage_account" {
  sensitive = true
  value     = module.sap_library.tfstate_storage_account
}

output "sapbits_storage_account_name" {
  value = module.sap_library.sapbits_storage_account_name
}

output "sapbits_sa_resource_group_name" {
  value = module.sap_library.sapbits_sa_resource_group_name
}

output "storagecontainer_tfstate" {
  sensitive = true
  value     = module.sap_library.storagecontainer_tfstate
}

output "storagecontainer_sapbits_name" {
  sensitive = true
  value     = module.sap_library.storagecontainer_sapbits_name
}

output "fileshare_sapbits_name" {
  sensitive = true
  value     = module.sap_library.fileshare_sapbits_name
}

output "user_vault_name" {
  sensitive = true
  value     = module.sap_library.user_vault_name
}

output "remote_state_resource_group_name" {
  value = module.sap_library.remote_state_resource_group_name
}

output "remote_state_storage_account_name" {
  value = module.sap_library.remote_state_storage_account_name
}

output "remote_state_container_name" {
  value = module.sap_library.remote_state_container_name
}

output "saplibrary_environment" {
  value = local.environment
}

output "saplibrary_subscription_id" {
  value = local.spn.subscription_id
}

output "tfstate_resource_id" {
  value = module.sap_library.tfstate_resource_id
}