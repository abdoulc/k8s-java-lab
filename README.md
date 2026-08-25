# ☕ Java × Kubernetes Lab

> A hands-on Kubernetes learning project built with Spring Boot,
> Docker and Kind.

## 🎯 Why this project?

I'm learning Kubernetes through hands-on experimentation.

Instead of only studying Kubernetes concepts, I'm building a small
Java microservices platform and intentionally breaking it to understand
how Kubernetes reacts.

The goal is to document the journey from a simple Spring Boot application
to a more complete Kubernetes-based deployment.

## Prerequisites

The lab is currently developed and validated from Windows with PowerShell.
Linux and macOS scripts will be added after the Windows setup is reproducible.

| Tool | Requirement | Used for |
| --- | --- | --- |
| Java | JDK 21 or newer | Compiling the Spring Boot services targeting Java 21 |
| Maven | 3.8 or newer | Building and testing both services |
| Docker | Docker Engine or Docker Desktop, using Linux containers | Building images and running Kind |
| Docker Compose | Compose v2 (`docker compose`) | Running the services without Kubernetes |
| Kind | A recent version | Creating the local Kubernetes cluster |
| kubectl | A version compatible with the Kind cluster | Deploying and observing Kubernetes resources |
| PowerShell | 7 recommended | Running the initial setup and experiment scripts |

Docker Desktop users must enable hardware virtualization and start Docker
before creating the cluster. Allocate enough resources for three Kind nodes;
4 CPUs and 6 GB of memory available to Docker are a practical starting point.

Verify the workstation before continuing:

```powershell
java -version
mvn -version
docker version
docker compose version
kind version
kubectl version --client
```

Also verify that the Docker daemon is reachable:

```powershell
docker info
```

The repository does not yet provide a one-command setup. Until that workflow
is implemented and validated, do not assume that the files under `k8s/` are a
complete installation procedure. The next Sprint 1 steps will add the build,
image loading, cluster setup and teardown commands.

### Run the application tests

Each service has focused HTTP controller tests. Run them independently from the
repository root:

```powershell
mvn -f services/user-service/pom.xml test
mvn -f services/order-service/pom.xml test
```

### Build the applications

Build and test the executable JARs locally:

```powershell
mvn -f services/user-service/pom.xml clean package
mvn -f services/order-service/pom.xml clean package
```

The Dockerfiles are multi-stage builds. They compile and test their service in
a Maven builder image, then copy only the executable JAR into a Java runtime
image. A pre-existing local `target/` directory is therefore not required.

Build both container images from the repository root:

```powershell
docker compose build
```

Verify the expected local image tags:

```powershell
docker image inspect k8s-java-lab/user-service:1.0
docker image inspect k8s-java-lab/order-service:1.0
```

## Architecture overview

```mermaid
flowchart LR
    Order[Order Service<br/>Deployment] -->|HTTP<br/>user-service:8080| Service[User Service<br/>ClusterIP]
    Service --> Pods[User Service Pods<br/>readiness + liveness probes]
    HPA[HPA<br/>60% CPU target<br/>1–5 replicas] -. scales .-> Pods
```

- `order-service` calls User Service through Kubernetes internal DNS.
- The `user-service` ClusterIP routes traffic only to ready Pods.
- The Deployment provides self-healing and rolling updates.
- The HPA scales User Service between 1 and 5 replicas based on CPU usage.

See the [detailed architecture documentation](docs/architecture/README.md).

## Documentation

- [Architecture](docs/architecture/README.md)
- [Demo 1](docs/demo-1/README.md): notes and demonstrated Kubernetes features
- [Watch Demo 1](docs/demo-1/From%20Java%20to%20Kubernetes%20Demo%201.mp4)

## Concepts learned

| Concept | What I learned |
| --- | --- |
| Pod | Smallest deployable unit |
| Deployment | Desired state and replica management |
| Service | Stable networking for Pods |
| DNS | Service-to-service discovery |
| Readiness Probe | Controls whether a Pod receives traffic |
| Liveness Probe | Determines whether a container should be restarted |
| Startup Probe | Gives slow-starting applications time to initialize |
| Resources | CPU / memory requests and limits |
| Metrics Server | Provides resource metrics |
| HPA | Automatically scales replicas based on CPU |
| Self-healing | Kubernetes replaces failed Pods |
