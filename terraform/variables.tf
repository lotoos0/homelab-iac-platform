variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint"
  type        = string
}

variable "proxmox_node_name" {
  description = "Proxmox VE node name"
  type        = string
}

variable "proxmox_template_vm_id" {
  description = "VM ID of the Proxmox Debian template"
  type        = number
}

variable "test_vm_name" {
  description = "Name of the disposable Terraform test VM"
  type        = string
}

