# Scalable Distributed Key-Value Store with Eventual Consistency

## Project Overview
This project implements a highly available and scalable distributed key-value store inspired by Amazon's Dynamo. The system ensures eventual consistency and is designed to handle node failures gracefully while maintaining uptime. The core features include replication, partitioning using consistent hashing, vector clocks for versioning, and gossip-based membership protocols.

## Objectives
- Build a key-value store with eventual consistency using decentralized architecture.
- Implement partitioning, replication, and quorum mechanisms.
- Deploy the system on Kubernetes using AWS EKS.
- Integrate monitoring and observability using Prometheus and Grafana.

## Key Features
- **Consistent Hashing**: Partition data across multiple nodes using consistent hashing.
- **Replication**: Ensure data durability and availability across multiple nodes.
- **Hinted Handoff**: Enable write operations to succeed even when some nodes are down.
- **Quorum-Based Reads/Writes**: Use quorum consistency with configurable values for R (read) and W (write).
- **Vector Clocks**: Implement vector clocks for managing concurrent writes and conflict resolution.
- **Gossip Protocol**: Manage node membership and failure detection using a gossip protocol.
- **Observability**: Monitor system health using Prometheus and visualize metrics with Grafana.

## Technology Stack
- **Languages**: Python or Golang
- **Storage Engines**: LevelDB or RocksDB
- **Networking**: gRPC (for inter-node communication)
- **Orchestration**: Kubernetes on AWS EKS
- **Infrastructure as Code**: Terraform (for AWS provisioning)
- **Monitoring**: Prometheus, Grafana, Jaeger (for tracing), ELK Stack
- **Cloud Platform**: AWS (EKS, S3 for backups, CloudWatch)

## Project Stages
1. **Infrastructure Setup**: Provision AWS EKS using Terraform and configure networking and security.
2. **Core Key-Value Store**: Implement core functionality (consistent hashing, replication, vector clocks).
3. **Replication & Quorum**: Add replication across nodes and configure quorum for reads/writes.
4. **Observability**: Set up Prometheus, Grafana, and Jaeger for monitoring and distributed tracing.
5. **Fault Tolerance & Testing**: Conduct chaos testing to verify resilience under node failures.

## Architecture Overview
The system architecture is based on Amazon Dynamo's principles. It distributes data across nodes using consistent hashing, ensuring no single point of failure. Replication across nodes ensures high availability, while eventual consistency is achieved by using vector clocks and quorum-based read/write operations.

Please refer to the [Architecture Documentation](docs/architecture.md) for detailed information.

## Installation and Setup

### Prerequisites:
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured.
- [Terraform](https://www.terraform.io/) installed.
- [Docker](https://www.docker.com/) and [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.
- An AWS account with permissions to create EKS clusters.

### Steps:
1. **Clone the repository**:
    ```bash
    git clone https://github.com/your-repo/distributed-kv-store.git
    cd distributed-kv-store
    ```

2. **Set up EKS cluster using Terraform**:
    ```bash
    cd deploy/terraform
    terraform init
    terraform apply
    ```

3. **Deploy the key-value store on Kubernetes**:
    ```bash
    kubectl apply -f deploy/kubernetes/
    ```

4. **Set up monitoring**:
    Follow the instructions in the [Observability Documentation](docs/observability.md).

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
