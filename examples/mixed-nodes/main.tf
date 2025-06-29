# Sample EKS Cluster with Mixed Node Types (EC2 + Fargate)
# This example demonstrates how to use the EKS module with both EC2 node groups and Fargate profiles

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

# Data source for EKS-optimized AMI
data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.kubernetes_version}-v*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EKS Cluster Module with Mixed Node Types
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

  # EC2 Node Groups Configuration
  node_groups = {
    general = {
      capacity_type   = "ON_DEMAND"
      instance_types  = ["t3.medium", "t3.large"]
      desired_size    = 2
      max_size        = 5
      min_size        = 1
      max_unavailable = 1
      ami_id          = data.aws_ami.eks_optimized.id
      tags = {
        Name = "${var.cluster_name}-general-nodes"
        Environment = var.environment
        NodeGroup = "general"
      }
    }
    spot = {
      capacity_type   = "SPOT"
      instance_types  = ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
      desired_size    = 1
      max_size        = 3
      min_size        = 0
      max_unavailable = 1
      ami_id          = data.aws_ami.eks_optimized.id
      tags = {
        Name = "${var.cluster_name}-spot-nodes"
        Environment = var.environment
        NodeGroup = "spot"
      }
    }
  }

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
    batch = {
      namespace = "batch"
      labels = {
        Environment = var.environment
        FargateProfile = "batch"
        App = "batch-processing"
      }
      tags = {
        Name = "${var.cluster_name}-batch-fargate"
        Environment = var.environment
        FargateProfile = "batch"
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

output "node_groups" {
  description = "Map of EKS node groups created"
  value       = module.eks_cluster.node_groups
}

output "fargate_profiles" {
  description = "Map of EKS Fargate profiles created"
  value       = module.eks_cluster.fargate_profiles
} 