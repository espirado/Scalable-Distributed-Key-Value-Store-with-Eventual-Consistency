# VPC Setup Documentation

## **Project Context**
This document details the reasoning and setup process for the Virtual Private Cloud (VPC) configuration in our scalable, distributed key-value store project. The VPC is designed to provide a secure and scalable networking layer for the underlying AWS infrastructure, including the EKS (Elastic Kubernetes Service) cluster.

---

## **1. Reasoning Behind VPC Configuration**

### **CIDR Block Selection (10.0.0.0/16)**
We chose the CIDR block `10.0.0.0/16` to allow for ample IP address space within the VPC. This block provides 65,536 IP addresses, which should accommodate any future scaling of subnets, instances, and other networking components. The large IP range allows flexibility for future expansion without needing to reconfigure the entire VPC.

- **Why /16?**
  - A `/16` CIDR block allows us to split our IP space into multiple subnets while keeping plenty of room for additional services.
  - It ensures that we can assign subnets for different services (e.g., public and private subnets) while keeping the same VPC.

---

## **2. Subnet Segmentation**

We divided the VPC into **public** and **private** subnets across two **Availability Zones** (AZs) for high availability. Each AZ is designed to handle failover in case one AZ becomes unavailable, ensuring the resilience of the services running in our infrastructure.

### **Public Subnets (10.0.1.0/24, 10.0.2.0/24)**
The public subnets are designated for resources that require internet access, such as:
- NAT Gateways
- Internet-facing Load Balancers

Each public subnet is allocated `/24` IP ranges, providing 256 IP addresses per subnet, which is more than sufficient for the number of resources that will reside in the public subnets.

- **Why /24 for public subnets?**
  - We anticipate limited external-facing resources (e.g., load balancers, NAT gateways) in the public subnets, so a `/24` block (256 IPs) is more than sufficient.
  - Public subnets have direct access to the internet through an **Internet Gateway**.

### **Private Subnets (10.0.3.0/24, 10.0.4.0/24)**
The private subnets host internal resources like EKS worker nodes, RDS instances, and other services that don’t need direct internet exposure. Outbound traffic is routed through a **NAT Gateway** in the public subnet, allowing secure communication with the internet when necessary.

- **Why /24 for private subnets?**
  - We assign `/24` blocks for private subnets to ensure we have enough IP addresses for scaling internal resources, such as EKS worker nodes.
  - Private subnets are isolated from the internet and use NAT Gateways for secure outbound traffic.

### **Availability Zones (us-east-1a, us-east-1b)**
We chose two availability zones (`us-east-1a` and `us-east-1b`) to provide high availability. By distributing resources across multiple AZs, we ensure resilience in the event of an AZ outage.

- **Why multiple AZs?**
  - Distributing subnets across multiple AZs ensures high availability and fault tolerance.
  - If one AZ experiences an issue, the services running in the other AZ will continue to function, minimizing downtime.

---

## **3. Internet Gateway and NAT Gateway Configuration**

### **Internet Gateway (IGW)**
An Internet Gateway is attached to the VPC to allow resources in the public subnets to access the internet. This is crucial for external-facing services, such as load balancers.

- **Why an IGW?**
  - Internet-facing services like load balancers require a route to the internet.
  - The IGW ensures that public subnets can send and receive traffic from the internet.

### **NAT Gateway**
The NAT Gateway is provisioned in the public subnet to allow private subnet resources (e.g., EKS worker nodes) to access the internet without exposing them to inbound traffic.

- **Why use a NAT Gateway?**
  - Private subnets are isolated from direct internet access for security reasons.
  - NAT Gateways provide secure outbound access while maintaining this isolation.

---

## **4. Routing Configuration**

### **Public Subnets Routing**
Traffic in public subnets is routed through the Internet Gateway (IGW) to allow inbound and outbound traffic to the internet. This is managed through route tables.

### **Private Subnets Routing**
The private subnets are configured to route outbound traffic through the NAT Gateway for secure internet access, while inbound traffic is restricted unless specifically allowed by security groups or NACLs.

---

## **5. Security Considerations**

We have implemented a security-first approach throughout the networking setup. Private subnets are isolated from the internet, and all communication from the private subnets to the internet is routed through the NAT Gateway. Additionally, Security Groups and Network ACLs are configured with least-privilege principles to control access between subnets and services.

---

## **6. VPC Flow Logs**

We enabled VPC Flow Logs to monitor and log all network traffic in and out of the VPC. This enables us to analyze traffic patterns, detect anomalies, and troubleshoot network issues.

- **Why VPC Flow Logs?**
  - Flow logs are critical for network observability and can help in identifying traffic bottlenecks or malicious activities.
  - Logs are stored in CloudWatch for real-time analysis.

---

## **Conclusion**

This VPC setup provides a secure and scalable foundation for the key-value store project. The careful segmentation of subnets, use of NAT and Internet Gateways, and security-focused configuration ensure that the VPC can scale as the project grows, while maintaining a strong security posture.
