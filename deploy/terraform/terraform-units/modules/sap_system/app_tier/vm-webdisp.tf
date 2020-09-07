# Create Web dispatcher NICs
resource "azurerm_network_interface" "web" {
  count                         = local.enable_deployment ? local.webdispatcher_count : 0
  name                          = length(local.prefix) > 0 ? format("%s_%s%s", local.prefix, var.web_vm_names[count.index], var.resource_suffixes["nic"]) : format("%s%s", var.web_vm_names[count.index], var.resource_suffixes["nic"])
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = local.web_sizing.compute.accelerated_networking

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = local.sub_web_deployed.id
    private_ip_address            = try(local.web_nic_ips[count.index], local.sub_web_defined ? cidrhost(local.sub_web_prefix, (tonumber(count.index) + local.ip_offsets.web_vm)) : cidrhost(local.sub_app_prefix, (tonumber(count.index) * -1 + local.ip_offsets.web_vm)))
    private_ip_address_allocation = "static"
  }
}

# Create the Linux Web dispatcher VM(s)
resource "azurerm_linux_virtual_machine" "web" {
  count                        = local.enable_deployment ? (upper(local.app_ostype) == "LINUX" ? local.webdispatcher_count : 0) : 0
  name                         = length(local.prefix) > 0 ? format("%s_%s%s", local.prefix, var.web_vm_names[count.index], var.resource_suffixes["vm"]) : format("%s%s", var.web_vm_names[count.index], var.resource_suffixes["vm"])
  computer_name                = var.web_vm_names[count.index]
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.web[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]
  size                            = local.web_sizing.compute.vm_size
  admin_username                  = local.authentication.username
  disable_password_authentication = true

  os_disk {
    name                 = length(local.prefix) > 0 ? format("%s_%s%s", local.prefix, var.web_vm_names[count.index], var.resource_suffixes["osdisk"]) : format("%s%s", var.web_vm_names[count.index], var.resource_suffixes["osdisk"])
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = local.app_custom_image ? local.app_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.app_custom_image ? 0 : 1)
    content {
      publisher = local.app_os.publisher
      offer     = local.app_os.offer
      sku       = local.app_os.sku
      version   = local.app_os.version
    }
  }

  admin_ssh_key {
    username   = local.authentication.username
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}

# Create the Windows Web dispatcher VM(s)
resource "azurerm_windows_virtual_machine" "web" {
  count                        = local.enable_deployment ? (upper(local.app_ostype) == "WINDOWS" ? local.webdispatcher_count : 0) : 0
  name                         = length(local.prefix) > 0 ? format("%s_%s%s", local.prefix, var.web_vm_names[count.index], var.resource_suffixes["vm"]) : format("%s%s", var.web_vm_names[count.index], var.resource_suffixes["vm"])
  computer_name                = var.web_vm_names[count.index]
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.web[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids = [
    azurerm_network_interface.web[count.index].id
  ]
  size           = local.web_sizing.compute.vm_size
  admin_username = local.authentication.username
  admin_password = local.authentication.password

  os_disk {
    name                 = length(local.prefix) > 0 ? format("%s_%s%s", local.prefix, var.web_vm_names[count.index], var.resource_suffixes["osdisk"]) : format("%s%s", var.web_vm_names[count.index], var.resource_suffixes["osdisk"])
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = local.app_custom_image ? local.app_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.app_custom_image ? 0 : 1)
    content {
      publisher = local.app_os.publisher
      offer     = local.app_os.offer
      sku       = local.app_os.sku
      version   = local.app_os.version
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}

# Creates managed data disk
resource "azurerm_managed_disk" "web" {
  count                = local.enable_deployment ? length(local.web-data-disks) : 0
  name                 = length(local.prefix) > 0 ? format("%s_%s%s", local.prefix, var.web_vm_names[count.index], local.web-data-disks[count.index].suffix) : format("%s%s", var.web_vm_names[count.index], local.web-data-disks[count.index].suffix)
  location             = var.resource-group[0].location
  resource_group_name  = var.resource-group[0].name
  create_option        = "Empty"
  storage_account_type = local.web-data-disks[count.index].disk_type
  disk_size_gb         = local.web-data-disks[count.index].size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "web" {
  count                     = local.enable_deployment ? length(azurerm_managed_disk.web) : 0
  managed_disk_id           = azurerm_managed_disk.web[count.index].id
  virtual_machine_id        = upper(local.app_ostype) == "LINUX" ? azurerm_linux_virtual_machine.web[local.web-data-disks[count.index].vm_index].id : azurerm_windows_virtual_machine.web[local.web-data-disks[count.index].vm_index].id
  caching                   = local.web-data-disks[count.index].caching
  write_accelerator_enabled = local.web-data-disks[count.index].write_accelerator
  lun                       = count.index
}
