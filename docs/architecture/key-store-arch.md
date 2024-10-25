# Distributed Key-Value Store Architecture Documentation

## 1. Infrastructure Architecture

### 1.1 Network Layer
```mermaid
graph TB
    subgraph AWS_Cloud["AWS Cloud (us-east-1)"]
        subgraph VPC["VPC (10.0.0.0/16)"]
            subgraph AZ1["Availability Zone A"]
                PS1[Public Subnet<br/>10.0.96.0/19]
                PRS1[Private Subnet<br/>10.0.0.0/19]
                NAT1[NAT Gateway 1]
            end
            
            subgraph AZ2["Availability Zone B"]
                PS2[Public Subnet<br/>10.0.128.0/19]
                PRS2[Private Subnet<br/>10.0.32.0/19]
                NAT2[NAT Gateway 2]
            end
            
            subgraph AZ3["Availability Zone C"]
                PS3[Public Subnet<br/>10.0.160.0/19]
                PRS3[Private Subnet<br/>10.0.64.0/19]
                NAT3[NAT Gateway 3]
            end
            
            subgraph Security["Security Layer"]
                SG[Security Groups]
                NACL[Network ACLs]
                FL[Flow Logs]
            end
        end
    end
```

### 1.2 Compute Layer (EKS)
```mermaid
graph TB
    subgraph EKS_Cluster["EKS Cluster"]
        subgraph Control_Plane["Control Plane"]
            API[API Server]
            ETCD[etcd]
            CM[Controller Manager]
        end
        
        subgraph Node_Groups["Node Groups"]
            NG1[General Purpose<br/>t3.medium]
            NG2[KVStore Nodes<br/>t3.large]
        end
        
        subgraph Add_ons["Add-ons"]
            CNI[VPC CNI]
            DNS[CoreDNS]
            PROXY[kube-proxy]
            LB[AWS LB Controller]
        end
    end
```

## 2. Key-Value Store Design

### 2.1 Data Distribution
```mermaid
graph LR
    subgraph Consistent_Hashing["Consistent Hashing Ring"]
        N1[Node 1]
        N2[Node 2]
        N3[Node 3]
        N1 --> N2
        N2 --> N3
        N3 --> N1
    end
```

### 2.2 Key Components

1. **Consistent Hashing**
   - Ring-based topology
   - Virtual nodes for better distribution
   - Node addition/removal handling
   ```plaintext
   Hash Space: [0 - 2^128-1]
   Virtual Nodes per Physical Node: 128
   Distribution Algorithm: SHA-256
   ```

2. **Vector Clocks**
   - Causality tracking
   - Conflict detection
   - Version reconciliation
   ```plaintext
   Format: {node_id: counter}
   Example: {node1: 1, node2: 3, node3: 2}
   ```

3. **Replication**
   - N copies (configurable)
   - Preference list generation
   - Quorum-based operations
   ```plaintext
   N = 3 (replicas)
   W = 2 (write quorum)
   R = 2 (read quorum)
   ```

4. **Gossip Protocol**
   - Membership management
   - Failure detection
   - State dissemination
   ```plaintext
   Gossip Interval: 1 second
   Failure Detection: Phi-accrual
   Suspicion Threshold: 5 seconds
   ```

### 2.3 Data Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant LB as Load Balancer
    participant N1 as Coordinator Node
    participant N2 as Replica Node
    participant N3 as Replica Node
    
    C->>LB: Write Request
    LB->>N1: Route Request
    N1->>N1: Generate Vector Clock
    par Parallel Write
        N1->>N2: Replicate
        N1->>N3: Replicate
    end
    N2-->>N1: Ack
    N3-->>N1: Ack
    N1-->>LB: Success
    LB-->>C: Response
```

## 3. Reliability Patterns

### 3.1 Write Path
```plaintext
1. Client Request → Load Balancer
2. Route to Coordinator Node
3. Update Vector Clock
4. Write to Local Storage
5. Replicate to N-1 nodes
6. Wait for W-1 acknowledgments
7. Respond to Client
```

### 3.2 Read Path
```plaintext
1. Client Request → Load Balancer
2. Route to Coordinator Node
3. Read from Local Storage
4. Request from R-1 replicas
5. Vector Clock Comparison
6. Resolve Conflicts
7. Return Latest Version
```

### 3.3 Failure Handling
1. **Node Failure**
   - Detection via gossip
   - Rebalance ring
   - Repair replicas

2. **Network Partition**
   - Sloppy quorum
   - Hinted handoff
   - Anti-entropy repair

3. **Split Brain**
   - Quorum-based resolution
   - Vector clock reconciliation
   - Merkle tree synchronization

## 4. Implementation Components

### 4.1 Core Services
```mermaid
graph TB
    subgraph KVStore_Components
        API[API Service]
        COORD[Coordinator Service]
        REPL[Replication Service]
        MEMB[Membership Service]
        STOR[Storage Service]
    end
```

### 4.2 Supporting Services
1. **Health Checking**
   - Liveness probe
   - Readiness probe
   - Startup probe

2. **Metrics & Monitoring**
   - Request latencies
   - Replication lag
   - Storage metrics
   - Network metrics

3. **Operations**
   - Node bootstrap
   - Data migration
   - Version reconciliation
   - State transfer

## 5. Infrastructure Components
```plaintext
├── VPC
│   ├── Public Subnets (3)
│   ├── Private Subnets (3)
│   └── NAT Gateways (3)
├── Security
│   ├── Security Groups
│   ├── NACLs
│   └── Flow Logs
├── EKS
│   ├── Control Plane
│   ├── Node Groups
│   └── Add-ons
└── Load Balancer
    ├── Target Groups
    └── Health Checks
```



