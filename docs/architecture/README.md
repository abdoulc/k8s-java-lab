# Architecture

The lab runs two Spring Boot microservices in a local Kubernetes cluster.
`order-service` calls `user-service` through the internal Kubernetes DNS name
`user-service:8080`.

```mermaid
flowchart LR
    Client[Demo client]

    subgraph Cluster[Local Kubernetes cluster]
        direction LR

        subgraph Orders[Order Service Deployment]
            O1[order-service Pod]
            O2[order-service Pod]
        end

        USVC[user-service<br/>ClusterIP :8080]

        subgraph Users[User Service Deployment]
            U1[user-service Pod]
            U2[user-service Pod]
            UN[user-service Pod ...]
        end

        HPA[HorizontalPodAutoscaler<br/>CPU target: 60%<br/>1–5 replicas]

        O1 -->|HTTP| USVC
        O2 -->|HTTP| USVC
        USVC --> U1
        USVC --> U2
        USVC --> UN
        HPA -. scales .-> Users
    end

    Client -. demo traffic .-> USVC
```

## Components

| Component | Kubernetes resource | Role |
| --- | --- | --- |
| User Service | Deployment | Runs the Spring Boot user API with CPU and memory requests/limits. |
| User Service | ClusterIP Service | Provides the stable `user-service:8080` endpoint and routes traffic to ready Pods. |
| User Service | HPA | Scales the Deployment from 1 to 5 replicas around a 60% average CPU target. |
| Order Service | Deployment | Runs the order API and calls User Service through internal DNS. |

`order-service` intentionally has no Kubernetes Service in this iteration:
nothing inside the cluster needs a stable network endpoint to call it yet.

## Health and recovery

User Service exposes three health mechanisms:

- The startup probe waits for `/actuator/health` before normal probes take over.
- The readiness probe checks `/ready`; an unready Pod is excluded from Service routing.
- The liveness probe checks `/actuator/health`; repeated failures cause a container restart.

The Deployment recreates deleted Pods to reconcile the actual state with the
desired state. During sustained CPU load, the HPA adds replicas; after the load
stops and the stabilization window passes, it scales the workload back down.

## Source files

- [`user-service-deployment.yaml`](../../k8s/sprint-1/user-service-deployment.yaml)
- [`user-service-service.yaml`](../../k8s/sprint-1/user-service-service.yaml)
- [`user-service-hpa.yaml`](../../k8s/sprint-1/user-service-hpa.yaml)
- [`order-service-deployment.yaml`](../../k8s/sprint-1/order-service-deployment.yaml)
