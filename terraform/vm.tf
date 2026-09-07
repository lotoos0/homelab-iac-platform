resource "proxmox_cloned_vm" "test" {
  node_name = var.proxmox_node_name
  name      = var.test_vm_name

  clone = {
    source_vm_id = var.proxmox_template_vm_id
    full         = true
  }
}
