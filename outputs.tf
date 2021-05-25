output "password" {
  value     = random_password.apim.result
  sensitive = true
}