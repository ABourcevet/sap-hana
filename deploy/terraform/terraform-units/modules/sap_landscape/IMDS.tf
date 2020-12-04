variable "api-version" {
  description = "IMDS API Version"
  default     = "2019-04-30"
}

variable "auto-deploy-version" {
  description = "Version for automated deployment"
  default     = "Fe"
}

variable "scenario" {
  description = "Deployment Scenario"
  default     = "sap_landscape"
}

variable "max_timeout" {
  description = "Maximum time allowed to spend for curl"
  default     = 10
}

// Registers the current deployment state with Azure's Metadata Service (IMDS)
resource "azurerm_virtual_machine_extension" "iscsi" {
  count                = local.iscsi_count
  name                 = "IMDS"
  virtual_machine_id   = azurerm_linux_virtual_machine.iscsi[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "curl --silent --output /dev/null --max-time ${var.max_timeout} -i -H \"Metadata: \"true\"\" -H \"user-agent: SAP AutoDeploy/${var.auto-deploy-version}; scenario=iscsi; deploy-status=Terraform_${var.scenario}\" http://169.254.169.254/metadata/instance?api-version=${var.api-version}"
    }
SETTINGS

}
