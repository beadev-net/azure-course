locals {
  tags = {
    environment = "dev"
    date        = formatdate("YYYY-MM-DD", timestamp())
  }
}