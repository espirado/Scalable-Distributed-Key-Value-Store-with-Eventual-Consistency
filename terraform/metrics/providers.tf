terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
      configuration_aliases = [kubernetes]
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
      configuration_aliases = [helm]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}