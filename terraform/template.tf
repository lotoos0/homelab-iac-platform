data "proxmox_vm" "debian_template" {
  node_name = var.proxmox_node_name
  id        = var.proxmox_template_vm_id
}
