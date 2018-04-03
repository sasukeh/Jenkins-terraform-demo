# Before executing this tf script, you should do following procedure.
# 1. az login
# 2. az account list -o table
# 3. az account set -s <subscription ID>
# 4. create resource_group
# az group create -g test -l japaneast
# az 

# -----
# Network Configuration
# -----
resource "azurerm_resource_group" "test" {
  name     = "acceptanceTestResourceGroup1"
  location = "Japan East"
}

resource "azurerm_virtual_network" "test" {
  name                = "acceptanceTestVirtualNetwork1"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "testsubnet"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
  name                = "acceptanceTestNetworkInterface1"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    environment = "staging"
  }
}

resource "azurerm_virtual_machine" "virtual_machine" {
  name                  = "test"
#  location              = "${var.location}"
  location              = "japaneast"
  resource_group_name   = "test"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_DS1_v2"

  identity = {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "test"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "test"
    admin_username = "username"
    admin_password = "password"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false
  }
}

resource "azurerm_virtual_machine_extension" "virtual_machine_extension" {
  name                 = "test"
#  location             = "${var.location}"
  location             = "japaneast"
  resource_group_name  = "test"
  virtual_machine_name = "${azurerm_virtual_machine.virtual_machine.name}"
  publisher            = "Microsoft.ManagedIdentity"
  type                 = "ManagedIdentityExtensionForWindows"
  type_handler_version = "1.0"

  settings = <<SETTINGS
    {
        "port": 50342
    }
SETTINGS
}

data "azurerm_subscription" "subscription" {}

data "azurerm_builtin_role_definition" "builtin_role_definition" {
  name = "Contributor"
}

# Grant the VM identity contributor rights to the current subscription
resource "azurerm_role_assignment" "role_assignment" {
  scope              = "${data.azurerm_subscription.subscription.id}"
  role_definition_id = "${data.azurerm_subscription.subscription.id}${data.azurerm_builtin_role_definition.builtin_role_definition.id}"
  principal_id       = "${lookup(azurerm_virtual_machine.virtual_machine.identity[0], "principal_id")}"

  lifecycle {
    ignore_changes = ["name"]
  }
}