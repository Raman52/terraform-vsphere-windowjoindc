provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = "Datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name          = "192.168.2.60/Resources"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = "Window-Template"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus  = 1
  memory    = 4096
  firmware  = "efi"
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  dynamic "disk" {
    for_each = range(var.disk_count)
    content {
      label = "disk${disk.value}"
      eagerly_scrub = "false"
      thin_provisioned = "true"
      size = var.disk_sizes[disk.value]
      unit_number = disk.value
    }
  }
  
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
    windows_options {
      computer_name  = "windowr1"
      workgroup      = "WORKGROUP" # Use this if not joining a domain, otherwise use domain details
      admin_password = "Admin@123" # Required for Windows customization
      run_once_command_list = [
      "powershell.exe -Command \"Get-Disk\"",
      "powershell.exe -Command \"Set-Disk -Number 1 -IsOffline $false\"",
      "powershell.exe -Command \"Initialize-Disk -Number 1 -PartitionStyle GPT\"",
      "powershell.exe -Command \"New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter\"",
      "powershell.exe -Command \"Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel 'hcl' -Confirm:$false\"",
      "powershell.exe -Command \"Get-Volume\""
      ]
    }

    network_interface {
      ipv4_address = "192.168.3.237"
      ipv4_netmask = 24
    }

    ipv4_gateway    = "192.168.3.1"
    dns_server_list = ["192.168.3.1"]
    }
  }
}

  
