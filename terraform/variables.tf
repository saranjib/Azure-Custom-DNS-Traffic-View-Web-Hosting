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
  description = "Your public IP CIDR for SSH access (Format: 225.168.50.3/32)" 
  type        = string
}

variable "location_map" {
  type = map(string)

  default = {
    primary   = "Central India"
    
  }
}

variable "dns_label_prefix" {
  description = "Globally unique Azure public IP DNS prefix" 
  type        = string
}
