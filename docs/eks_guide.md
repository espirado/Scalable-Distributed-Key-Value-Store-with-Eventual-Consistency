# EKS Cluster Setup and Configuration Guide

## Prerequisites

### 1. AWS CLI Installation and Configuration
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS CLI
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (us-east-1)
# - Default output format (json)
```

### 2. kubectl Installation
```bash
# For Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

### 3. AWS IAM Authenticator
```bash
# For Linux
curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64
chmod +x ./aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin

# Verify installation
aws-iam-authenticator help
```

## Required IAM Permissions

Ensure your AWS user has the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:*",
                "autoscaling:*",
                "elasticloadbalancing:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## Connecting to the Cluster

After the cluster is created:

```bash
# Update kubeconfig
aws eks update-kubeconfig --name ${local.name_prefix}-cluster --region us-east-1

# Verify connection
kubectl get nodes
```

## Verifying Add-ons

```bash
# Check EKS add-ons
kubectl get pods -n kube-system

# Expected add-ons:
# - CoreDNS
# - VPC CNI
# - kube-proxy
# - AWS Load Balancer Controller
```

## Common Commands

```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes

# Get namespaces
kubectl get ns

# Get pods across all namespaces
kubectl get pods -A

# Get service accounts
kubectl get serviceaccounts -A
```

## Troubleshooting

1. **Auth Issues**:
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Verify kubectl context
kubectl config get-contexts
```

2. **Node Issues**:
```bash
# Check node conditions
kubectl describe node <node-name>

# Check node logs
kubectl logs <node-name> -n kube-system
```

3. **Add-on Issues**:
```bash
# Check add-on status
kubectl get pods -n kube-system
kubectl describe pod <pod-name> -n kube-system
```