plugin "aws" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

config {
  module = true
  force  = false
}

# AWS Provider Configuration
rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_launch_configuration_invalid_image_id" {
  enabled = true
}

rule "aws_launch_configuration_invalid_instance_type" {
  enabled = true
}

rule "aws_launch_configuration_invalid_spot_price" {
  enabled = true
}

rule "aws_launch_template_invalid_instance_type" {
  enabled = true
}

rule "aws_launch_template_invalid_spot_price" {
  enabled = true
}

# EKS Specific Rules
rule "aws_eks_cluster_invalid_version" {
  enabled = true
}

rule "aws_eks_node_group_invalid_instance_type" {
  enabled = true
}

rule "aws_eks_node_group_invalid_ami_type" {
  enabled = true
}

rule "aws_eks_node_group_invalid_capacity_type" {
  enabled = true
}

# Security Rules
rule "aws_security_group_rule_invalid_port" {
  enabled = true
}

rule "aws_security_group_rule_invalid_protocol" {
  enabled = true
}

rule "aws_security_group_rule_invalid_type" {
  enabled = true
}

# VPC Rules
rule "aws_vpc_invalid_cidr_block" {
  enabled = true
}

rule "aws_subnet_invalid_cidr_block" {
  enabled = true
}

rule "aws_subnet_invalid_vpc_id" {
  enabled = true
}

# IAM Rules
rule "aws_iam_role_invalid_name" {
  enabled = true
}

rule "aws_iam_policy_invalid_name" {
  enabled = true
}

# KMS Rules
rule "aws_kms_key_invalid_description" {
  enabled = true
}

rule "aws_kms_alias_invalid_name" {
  enabled = true
}

# General Terraform Rules
rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

# Custom Rules for EKS Module
rule "terraform_required_providers" {
  enabled = true
  source  = "terraform"
}

rule "terraform_typed_variables" {
  enabled = true
  source  = "terraform"
} 