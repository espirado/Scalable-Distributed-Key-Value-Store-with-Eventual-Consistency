# Distributed Key-Value Store Documentation

## Table of Contents

1. [Infrastructure Architecture](architecture/infrastructure.md)
2. [Network Architecture](architecture/networking.md)
3. [Security Architecture](architecture/security.md)

## Quick Start
This documentation covers the infrastructure implementation of our distributed key-value store project. The infrastructure is managed using Terraform and deployed on AWS in the us-east-1 region.

## Infrastructure Overview
- VPC with 3 Availability Zones
- Public and Private Subnets
- NAT Gateways for private subnet connectivity
- Security Groups for different components
- Load Balancer for external access

## Key Components
- Distributed Key-Value Store Nodes
- Load Balancers
- Monitoring Infrastructure
- Security Components

## Repository Structure
```bash
.
├── alb/
├── backend.tf
├── main.tf
├── nacls/
├── nat/
├── outputs.tf
├── provider.tf
├── security_groups/
├── variables.tf
├── vpc/
└── vpc-flow/