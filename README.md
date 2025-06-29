# AWS EKS Terraform Module

A comprehensive Terraform module for creating secure, production-ready Amazon EKS (Elastic Kubernetes Service) clusters following AWS best practices and security guidelines.

## 🚀 Features

- **Multi-AZ VPC Setup**: Automatically creates a VPC with public and private subnets across multiple availability zones
- **EKS Cluster**: Production-ready EKS cluster with security best practices
- **Node Groups**: Support for both EC2 and Fargate node types
- **Security Hardening**: KMS encryption, security groups, IAM roles with least privilege
- **Monitoring & Logging**: Comprehensive control plane logging
- **OIDC Integration**: OpenID Connect provider for service account authentication
- **Flexible Configuration**: Support for on-demand, spot instances, and Fargate profiles

## 📋 Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- kubectl (for cluster interaction)

## 🏗️ Architecture

The module creates the following AWS resources:

```
┌─────────────────────────────────────────────────────────────┐
│                        EKS Cluster                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Public Subnet │  │  Private Subnet │  │ Private Subnet│ │
│  │   (AZ-1)        │  │   (AZ-1)        │  │   (AZ-2)     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Public Subnet │  │  Private Subnet │  │ Private Subnet│ │
│  │   (AZ-2)        │  │   (AZ-2)        │  │   (AZ-3)     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Public Subnet │  │  Private Subnet │  │ Private Subnet│ │
│  │   (AZ-3)        │  │   (AZ-3)        │  │   (AZ-3)     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Node Groups / Fargate                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ EC2 Nodes   │  │ Spot Nodes  │  │   Fargate Profiles  │  │
│  │ (On-Demand) │  │ (Cost Opt.) │  │   (Serverless)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🔒 Security Best Practices Implemented

### 1. **Network Security**
- **Private Subnets**: Worker nodes run in private subnets with NAT Gateway access
- **Security Groups**: Restrictive security groups with minimal required access
- **VPC Endpoints**: Private access to AWS services when possible
- **Network ACLs**: Default restrictive network ACLs

### 2. **Encryption**
- **KMS Encryption**: EKS secrets encrypted with customer-managed KMS keys
- **Key Rotation**: Automatic KMS key rotation enabled
- **TLS Configuration**: Strong TLS cipher suites for kubelet communication

### 3. **IAM Security**
- **Least Privilege**: IAM roles with minimal required permissions
- **OIDC Provider**: Secure service account authentication
- **Role Separation**: Separate roles for cluster, nodes, and Fargate profiles

### 4. **Cluster Security**
- **Control Plane Logging**: Comprehensive audit logging enabled
- **Private Endpoint**: Cluster API server accessible only from private subnets
- **Certificate Rotation**: Automatic certificate rotation enabled
- **Security Context**: Secure defaults for pod security

### 5. **Node Security**
- **Launch Templates**: Secure launch templates with IMDSv2
- **Container Runtime**: Containerd with secure configuration
- **Node Hardening**: Security-focused kubelet configuration

## 📖 Usage

### Basic Usage

```hcl
module "eks_cluster" {
  source = "./modules/eks"

  cluster_name        = "my-production-cluster"
  kubernetes_version  = "1.28"
  
  # VPC Configuration
  vpc_cidr           = "10.0.0.0/16"
  az_count           = 3
  
  # Node Groups
  node_groups = {
    general = {
      capacity_type   = "ON_DEMAND"
      instance_types  = ["t3.medium", "t3.large"]
      desired_size    = 2
      max_size        = 5
      min_size        = 1
      max_unavailable = 1
      ami_id          = data.aws_ami.eks_optimized.id
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### EC2 Node Groups Example

```hcl
# Data source for EKS-optimized AMI
data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.28-v*"]
  }
}

module "eks_cluster" {
  source = "./modules/eks"

  cluster_name = "my-eks-cluster"
  
  # EC2 Node Groups
  node_groups = {
    # General purpose nodes
    general = {
      capacity_type   = "ON_DEMAND"
      instance_types  = ["t3.medium", "t3.large"]
      desired_size    = 2
      max_size        = 5
      min_size        = 1
      max_unavailable = 1
      ami_id          = data.aws_ami.eks_optimized.id
      tags = {
        NodeGroup = "general"
        Environment = "production"
      }
    }
    
    # Spot instances for cost optimization
    spot = {
      capacity_type   = "SPOT"
      instance_types  = ["t3.medium", "t3.large", "t3a.medium"]
      desired_size    = 1
      max_size        = 3
      min_size        = 0
      max_unavailable = 1
      ami_id          = data.aws_ami.eks_optimized.id
      tags = {
        NodeGroup = "spot"
        Environment = "production"
      }
    }
  }
}
```

### Fargate Profiles Example

```hcl
module "eks_cluster" {
  source = "./modules/eks"

  cluster_name = "my-fargate-cluster"
  
  # Fargate Profiles
  fargate_profiles = {
    # Default namespace
    default = {
      namespace = "default"
      labels = {
        Environment = "production"
        FargateProfile = "default"
      }
    }
    
    # Monitoring namespace
    monitoring = {
      namespace = "monitoring"
      labels = {
        Environment = "production"
        FargateProfile = "monitoring"
        App = "monitoring"
      }
    }
    
    # Batch processing namespace
    batch = {
      namespace = "batch"
      labels = {
        Environment = "production"
        FargateProfile = "batch"
        App = "batch-processing"
      }
    }
  }
}
```

### Mixed Node Types Example

```hcl
module "eks_cluster" {
  source = "./modules/eks"

  cluster_name = "my-mixed-cluster"
  
  # EC2 Node Groups for compute-intensive workloads
  node_groups = {
    compute = {
      capacity_type   = "ON_DEMAND"
      instance_types  = ["c5.large", "c5.xlarge"]
      desired_size    = 2
      max_size        = 5
      min_size        = 1
      max_unavailable = 1
      ami_id          = data.aws_ami.eks_optimized.id
      tags = {
        NodeGroup = "compute"
        WorkloadType = "compute-intensive"
      }
    }
  }
  
  # Fargate Profiles for serverless workloads
  fargate_profiles = {
    serverless = {
      namespace = "serverless"
      labels = {
        Environment = "production"
        FargateProfile = "serverless"
        WorkloadType = "serverless"
      }
    }
  }
}
```

## 🎯 Node Type Comparison

### EC2 Node Groups

**Pros:**
- Full control over instance types and configurations
- Cost optimization with spot instances
- Better performance for compute-intensive workloads
- Persistent storage support
- Custom AMI support

**Cons:**
- Requires node management and scaling
- Higher operational overhead
- Need to handle node failures

**Best for:**
- Compute-intensive applications
- Applications requiring specific instance types
- Cost optimization with spot instances
- Applications needing persistent storage

### Fargate Profiles

**Pros:**
- Serverless - no node management
- Automatic scaling
- Pay-per-pod pricing
- No capacity planning needed
- Built-in security isolation

**Cons:**
- Limited instance type control
- Higher cost for sustained workloads
- No persistent storage (ephemeral only)
- Cold start latency

**Best for:**
- Variable workloads
- Development and testing environments
- Microservices with varying resource needs
- Applications with bursty traffic patterns

## 📊 Configuration Options

### Required Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `cluster_name` | Name of the EKS cluster | `string` | - |
| `kubernetes_version` | Kubernetes version | `string` | `"1.28"` |

### Optional Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `vpc_cidr` | VPC CIDR block | `string` | `"10.0.0.0/16"` |
| `az_count` | Number of availability zones | `number` | `3` |
| `private_subnet_cidrs` | Private subnet CIDRs | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` |
| `public_subnet_cidrs` | Public subnet CIDRs | `list(string)` | `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]` |
| `cluster_endpoint_public_access` | Enable public API access | `bool` | `true` |
| `enabled_cluster_log_types` | Control plane log types | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` |
| `node_groups` | EC2 node groups configuration | `map(object)` | `{}` |
| `fargate_profiles` | Fargate profiles configuration | `map(object)` | `{}` |

## 🔧 Examples

The module includes several example implementations:

1. **EC2 Nodes Only** (`examples/ec2-nodes/`)
   - Demonstrates EC2 node groups with on-demand and spot instances
   - Includes proper AMI selection and scaling configuration

2. **Fargate Only** (`examples/fargate-nodes/`)
   - Shows Fargate profiles for different namespaces
   - Demonstrates serverless EKS deployment

3. **Mixed Node Types** (`examples/mixed-nodes/`)
   - Combines EC2 and Fargate for optimal cost and performance
   - Shows workload-specific node group configuration

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd terraform-k8s
   ```

2. **Navigate to an example:**
   ```bash
   cd examples/ec2-nodes
   ```

3. **Copy and configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

4. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

## 📝 Outputs

The module provides comprehensive outputs:

- **Cluster Information**: ID, ARN, endpoint, version
- **VPC Information**: VPC ID, subnet IDs, CIDR blocks
- **Security Groups**: Cluster and node security group IDs
- **Node Groups**: Detailed information about EC2 node groups
- **Fargate Profiles**: Information about Fargate profiles
- **IAM Roles**: Role ARNs for cluster, nodes, and Fargate
- **KMS**: Encryption key information
- **OIDC**: Provider information for service accounts

## 🔍 Monitoring and Logging

### Control Plane Logging

The module enables comprehensive control plane logging:

- **API Server**: All API requests and responses
- **Audit**: Security audit events
- **Authenticator**: Authentication events
- **Controller Manager**: Controller events
- **Scheduler**: Pod scheduling decisions

### CloudWatch Integration

Logs are automatically sent to CloudWatch Logs for:
- Centralized log management
- Log retention and archival
- Log analysis and alerting
- Compliance and audit requirements

## 🛡️ Security Considerations

### Network Security
- All worker nodes run in private subnets
- NAT Gateway provides internet access for outbound traffic
- Security groups restrict traffic to necessary ports only
- VPC endpoints reduce exposure to internet

### Access Control
- IAM roles follow least privilege principle
- OIDC provider enables secure service account authentication
- Cluster endpoint access can be restricted to specific CIDRs
- Node groups use launch templates with secure defaults

### Data Protection
- EKS secrets encrypted with customer-managed KMS keys
- Automatic key rotation enabled
- TLS 1.2+ with strong cipher suites
- IMDSv2 required for node metadata access

## 🔄 Maintenance and Updates

### Kubernetes Version Updates
- Plan updates during maintenance windows
- Test in non-production environments first
- Follow AWS EKS version compatibility matrix
- Update node groups after control plane updates

### Node Group Updates
- Use rolling updates to minimize downtime
- Test updates on a subset of nodes first
- Monitor application health during updates
- Have rollback procedures ready

### Security Updates
- Regularly update EKS-optimized AMIs
- Monitor AWS security advisories
- Apply security patches promptly
- Review and update security group rules

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 References

- [AWS EKS Best Practices](https://aws.amazon.com/eks/resources/best-practices/)
- [EKS Security Best Practices](https://docs.aws.amazon.com/eks/latest/userguide/security.html)
- [EKS Node Groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)
- [EKS Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🆘 Support

For issues and questions:
1. Check the [examples](examples/) directory
2. Review the [variables](modules/eks/variables.tf) documentation
3. Open an issue on GitHub
4. Consult AWS EKS documentation 