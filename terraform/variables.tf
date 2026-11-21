variable "domain_name" {
  description = "Your registered custom domain"
  type        = string
  default     = "zenithcosmos.shop"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "/home/raj/Documents/Azure-Custom-DNS-Traffic-View-Web-Hosting/my-key.pub"
}


variable "admin_source_cidr" {
  description = "Your public IP CIDR for SSH access"
  type        = string
}

variable "dns_label_prefix" {
  description = "Globally unique Azure public IP DNS prefix"
  type        = string
  default     = "zenithweb2026"

}

variable "location_map" {
  type = map(string)

  default = {
    primary   = "Central India"
    secondary = "Southeast Asia"
  }
}
