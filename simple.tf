terraform {
  backend "remote" {
    organization = "MarcoDaniels"

    workspaces {
      name = "simple-static"
    }
  }

  required_providers {
    dhall = {
      source  = "awakesecurity/dhall"
      version = "0.0.1"
    }
  }
}

data "dhall" "config" {
  entrypoint = "./config.dhall"
}

locals {
  config = jsondecode(data.dhall.config.result)
}

output "names" {
  value = local.config.name
}