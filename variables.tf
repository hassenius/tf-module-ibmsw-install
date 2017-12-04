variable "server" {
  description = "Server to deploy software to"
}

variable "ssh_user" {
  description = "Username for Terraform to SSH to the VM. This is typically the default user with for the relevant cloud vendor. Default: ubuntu"
  default     = "ubuntu"
}

variable "ssh_key" {
  description = "Optional: Private key corresponding to the public key that the cloud servers are provisioned with."
  default     = ""
}

variable "ssh_key_content" {
  description = "Optional: Base64 encoded content of the private key corresponding to the public key that the cloud servers are provisioned with."
  default     = "None"
}

variable "ssh_password" {
  description = "Optional: Password to connect to newly created cloud server."
  default     = ""
}

variable "sw_archive" {
  description = "Location for downloading the archive"
  type        = "map"
  default     = {}
}
