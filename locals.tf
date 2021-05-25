locals {
  unique_name = format("%s%s", var.project_name, random_string.apim.result)
}