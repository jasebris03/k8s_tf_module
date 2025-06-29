# Sample EKS Cluster with Fargate Profiles
# This example demonstrates how to use the EKS module with Fargate profiles

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# EKS Cluster Module with Fargate Profiles
module "eks_cluster" {
  source = "../../modules/eks"

  cluster_name    = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # VPC Configuration
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  # Cluster Configuration
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # Fargate Profiles Configuration
  fargate_profiles = {
    default = {
      namespace = "default"
      labels = {
        Environment = var.environment
        FargateProfile = "default"
      }
      tags = {
        Name = "${var.cluster_name}-default-fargate"
        Environment = var.environment
        FargateProfile = "default"
      }
    }
    kube-system = {
      namespace = "kube-system"
      labels = {
        Environment = var.environment
        FargateProfile = "kube-system"
      }
      tags = {
        Name = "${var.cluster_name}-kube-system-fargate"
        Environment = var.environment
        FargateProfile = "kube-system"
      }
    }
    monitoring = {
      namespace = "monitoring"
      labels = {
        Environment = var.environment
        FargateProfile = "monitoring"
        App = "monitoring"
      }
      tags = {
        Name = "${var.cluster_name}-monitoring-fargate"
        Environment = var.environment
        FargateProfile = "monitoring"
      }
    }
  }

  # Tags
  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks_cluster.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks_cluster.cluster_security_group_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.eks_cluster.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.eks_cluster.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.eks_cluster.public_subnets
}

output "fargate_profiles" {
  description = "Map of EKS Fargate profiles created"
  value       = module.eks_cluster.fargate_profiles
} 