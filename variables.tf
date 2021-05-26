variable "location" {
  type = string
}

variable "apim_publishername" {
  type = string
}

variable "apim_publisheremail" {
  type = string
}

variable "apim_sku" {
  type = string
}

variable "username" {
  type = string
}

variable "database_name" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "snet_agw_address_space" {
  type = list(string)
}

variable "snet_api_address_space" {
  type = list(string)
}

variable "tags" {
  type = map(any)
}
