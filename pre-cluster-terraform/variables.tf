variable "username" {
  description = "unifi username"
  type        = string
  sensitive   = false
  default     = "gordogordo"
}

variable "password" {
  description = "unifi password"
  type        = string
  sensitive   = true
}

variable "insecure" {
  description = "unifi allow insecure"
  type        = bool
  default     = true
  sensitive   = false
}

variable "api_url" {
  description = "unifi api url endpoint"
  default     = "https://192.168.1.1"
  sensitive   = false
  type        = string
}

variable "harvester-new-vlan" {
  description = "a sample new vlan building for harvester"
  type        = number
  default     = 211
  sensitive   = false
}

variable "harvester-new-vlan-name" {
  description = "new vlan name for harvester"
  type        = string
  default     = "harvester-demo-vlan"
  sensitive   = false
}

variable "harvester-new-vlan-network-dhcp-start" {
  description = "harvester new vlan network dhcp start"
  type        = string
  default     = "192.168.211.6"
  sensitive   = false
}


variable "harvester-new-vlan-network-dhcp-end" {
  description = "harvester new vlan network dhcp end"
  type        = string
  default     = "192.168.211.244"
  sensitive   = false
}

variable "harvester-new-vlan-subnet-block" {
  description = "harvester new vlan subnet block"
  default     = "192.168.211.0/24"
  sensitive   = false
  type        = string
}
