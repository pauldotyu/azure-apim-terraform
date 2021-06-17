terraform {
  backend "remote" {
    organization = "contosouniversity"
    workspaces {
      name = "azure-apim-terraform"
    }
  }
}