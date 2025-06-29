# EKS Cluster Module Outputs

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnet_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

# Node Groups Outputs
output "node_groups" {
  description = "Map of EKS node groups created"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      id                = v.id
      arn               = v.arn
      status            = v.status
      node_group_name   = v.node_group_name
      cluster_name      = v.cluster_name
      node_role_arn     = v.node_role_arn
      subnet_ids        = v.subnet_ids
      instance_types    = v.instance_types
      capacity_type     = v.capacity_type
      scaling_config    = v.scaling_config
      update_config     = v.update_config
    }
  }
}

# Fargate Profiles Outputs
output "fargate_profiles" {
  description = "Map of EKS Fargate profiles created"
  value = {
    for k, v in aws_eks_fargate_profile.main : k => {
      id                  = v.id
      arn                 = v.arn
      status              = v.status
      fargate_profile_name = v.fargate_profile_name
      cluster_name        = v.cluster_name
      pod_execution_role_arn = v.pod_execution_role_arn
      subnet_ids          = v.subnet_ids
      selector            = v.selector
    }
  }
}

# KMS Outputs
output "kms_key_arn" {
  description = "The ARN of the KMS key used for EKS encryption"
  value       = aws_kms_key.eks.arn
}

output "kms_key_id" {
  description = "The ID of the KMS key used for EKS encryption"
  value       = aws_kms_key.eks.key_id
}

# OIDC Provider Outputs
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.url
}

# Node Security Group Outputs
output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

# IAM Role Outputs
output "node_group_iam_role_arns" {
  description = "Map of IAM role ARNs for node groups"
  value = {
    for k, v in aws_iam_role.eks_node_group : k => v.arn
  }
}

output "fargate_profile_iam_role_arns" {
  description = "Map of IAM role ARNs for Fargate profiles"
  value = {
    for k, v in aws_iam_role.eks_fargate_profile : k => v.arn
  }
} 