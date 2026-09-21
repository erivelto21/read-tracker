terraform {
  required_providers {
    mgc = {
      source  = "magalucloud/mgc"
      version = "~> 0.32"
    }
  }
}

provider "mgc" {
  api_key = var.api_key
  region  = var.region
}
