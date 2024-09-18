variable "vmlist" {
  description = "List of VMs from CSV"
  type        = list(map(string))
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "my-vm-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Australia East"
}

variable "hostpool_name" {
  description = "Name of the host pool"
  type        = string
  default     = "my-hostpool"
}

variable "workspace_name" {
  description = "Name of the AVD workspace"
  type        = string
  default     = "my-workspace"
}
