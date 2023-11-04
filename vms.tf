// Creating a Resource Group
resource "azurerm_resource_group" "myRG" {
  name     = "vm-rg"
  location = "West Europe"
}

// Creating a Resource for allocating public IP to VM
resource "azurerm_public_ip" "Public_IP" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name
  allocation_method   = "Dynamic"
}

// Creating a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name
}

// Creating a Subnet
resource "azurerm_subnet" "mySubnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.myRG.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

// Creating a network security group with network rule
resource "azurerm_network_security_group" "myNSG" {
  name                = "my-nsg"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name

  security_rule {
    name                       = "allow-all-traffic"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

// Creating a Network Interface Card
resource "azurerm_network_interface" "myNIC" {
  name                = "snipe-NIC"
  location            = azurerm_resource_group.myRG.location
  resource_group_name = azurerm_resource_group.myRG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mySubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Public_IP.id
  }
}

// Creating a Virtual Machine
resource "azurerm_linux_virtual_machine" "snipeit_vm" {
  name                  = "Snipe"
  location              = azurerm_resource_group.myRG.location
  resource_group_name   = azurerm_resource_group.myRG.name
  network_interface_ids = [azurerm_network_interface.myNIC.id]
  size                  = "Standard_DS1_v2"

  // Virtual Machine Disk Details
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  // Virtual Machine Image Details
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  computer_name                   = "snipeit"
  admin_username                  = var.USERNAME
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.USERNAME
    public_key = file("./snipe-key.pub")
  }

  provisioner "file" {
    source      = "./snipe-install.sh"
    destination = "/home/partha/install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/partha/install.sh",
      "cd /home/partha/",
      "sudo apt update",
      "sudo apt install dos2unix -y",
      "dos2unix install.sh",
      "sudo apt purge dos2unix -y",
      "sudo ./install.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = var.USERNAME        # SSH username for the VM
    private_key = file("./snipe-key") # SSH private key file
    host        = self.public_ip_address
  }
}

// Displaying the Public IP of Virtual Machine
output "PublicIP" {
  value = azurerm_linux_virtual_machine.snipeit_vm.public_ip_address
}
