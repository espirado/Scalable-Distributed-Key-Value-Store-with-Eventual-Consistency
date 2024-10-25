# Technology Stack

## Overview
The project leverages a combination of modern technologies to build, deploy, and monitor a highly available and scalable distributed key-value store. Below is a breakdown of the key technologies used across different areas of the project.

---

## **Languages**
- **Python** or **Golang**: Used for implementing core application logic, including key-value store operations, consistent hashing, vector clocks, and gossip protocol. 
    - Python is chosen for simplicity, while Golang offers better concurrency management for high-performance environments.
  
---

## **Storage Engines**
- **LevelDB** or **RocksDB**: Lightweight, embedded key-value stores that provide efficient local storage for each node in the system.
    - **LevelDB** is preferred for simplicity and faster setup.
    - **RocksDB** offers better performance for larger datasets and provides additional configuration for tuning.

---

## **Networking**
- **gRPC**: A modern, high-performance, open-source remote procedure call (RPC) framework that facilitates communication between nodes.
    - **gRPC** is used for low-latency, inter-node communication and efficient serialization.

---

## **Orchestration and Deployment**
- **Kubernetes on AWS EKS**: For container orchestration, we use Elastic Kubernetes Service (EKS) to deploy and manage the distributed nodes.
    - **Kubernetes** enables automatic scaling, self-healing, and efficient load balancing.
    - **Helm** charts are used to manage Kubernetes deployments for various components such as the application, Prometheus, and Grafana.

---

## **Infrastructure as Code (IaC)**
- **Terraform**: Used for automating the setup of AWS infrastructure.
    - **EKS** cluster, networking, and security configurations are managed via Terraform scripts.

---

## **Monitoring and Observability**
- **Prometheus**: Open-source monitoring tool for collecting and storing metrics on the system's performance.
- **Grafana**: Visualization tool integrated with Prometheus to create real-time dashboards for system health and performance.
- **Jaeger or OpenTelemetry**: Distributed tracing tool to track request paths across different nodes in the system.
- **ELK Stack (Elasticsearch, Logstash, Kibana)**: Centralized logging stack used to aggregate and search logs across nodes.

---

## **CI/CD and Automation**
- **GitHub Actions**: For automating code testing, deployment, and ensuring smooth continuous integration and continuous delivery (CI/CD) pipelines.
    - Includes workflows for linting, testing, and deploying infrastructure.
  
---

## **Cloud Platform**
- **AWS Services**:
    - **EKS (Elastic Kubernetes Service)**: Container orchestration for running Kubernetes clusters.
    - **S3**: Backup storage for persistent data snapshots.
    - **CloudWatch**: Additional logging and monitoring for AWS resources.
