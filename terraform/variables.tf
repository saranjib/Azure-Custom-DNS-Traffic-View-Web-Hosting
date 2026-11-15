variable "domain_name" {
  description = "Your registered custom domain"
  type        = string
  default     = "example.com"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "ssh_public_key" {
  description = "Your SSH public key"
  type        = string
}

variable "admin_source_cidr" {
  description = "Your public IP CIDR for SSH access"
  type        = string
}

variable "location_map" {
  type = map(string)

  default = {
    primary   = "Central India"
    secondary = "Southeast Asia"
  }
}

