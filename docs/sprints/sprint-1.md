# Sprint 1 — Kubernetes reproducibility

## Objective

The first sprint turns the two Spring Boot services into a Kubernetes lab that
can eventually be recreated from a clean workstation. The work is deliberately
incremental: each resource is introduced, validated, observed and documented
before the next resource is added.

The sprint is still in progress. Image loading and cluster lifecycle automation
are the next reproducibility steps.

## Starting point

The repository already contained:

- a User Service and an Order Service;
- Dockerfiles and a Docker Compose configuration;
- a three-node Kind configuration;
- Deployments for both applications;
- a ClusterIP Service and an HPA for User Service;
- health probes and resource requests/limits on User Service.

The files demonstrated several Kubernetes concepts, but there was no complete,
repeatable path from a clean clone to a running lab.

## Step 1 — Prerequisites and repeatable builds

### What was built

The required workstation tools and verification commands were added to the
main README. Both Dockerfiles were converted to multi-stage builds:

1. Maven compiles the service for Java 21 and runs its tests.
2. The Spring Boot plugin produces an executable JAR.
3. Only that JAR is copied into the Java runtime image.

The Docker build therefore no longer depends on a pre-existing local `target/`
directory.

### Commands used

```powershell
mvn -f services/user-service/pom.xml clean test
mvn -f services/order-service/pom.xml clean test
docker compose build
docker image inspect k8s-java-lab/user-service:1.0
docker image inspect k8s-java-lab/order-service:1.0
```

### Observation

Six focused HTTP tests passed: three for each service. Both container images
were then built successfully. The Docker build logs confirmed compilation with
Java `release 21` and execution of the tests inside the builder images.

### What this proves

Application compilation and image construction are reproducible from source.
It does not yet prove that the images are available inside Kind; Kind nodes use
their own container runtime image store.

## Step 2 — Namespace isolation

### What was built

A `k8s-java-lab` Namespace was created and every namespaced resource now
declares:

```yaml
metadata:
  namespace: k8s-java-lab
```

### Commands used

```bash
kubectl apply --dry-run=client -f k8s/sprint-1/
kubectl apply -f k8s/sprint-1/namespace.yaml
kubectl get namespace k8s-java-lab
kubectl get all -n k8s-java-lab
```

### Observation

The first Namespace manifest had been exported from the Kubernetes API and
contained `uid`, `resourceVersion`, `creationTimestamp`, `finalizers` and
`status`. Those server-managed fields were removed. The repository now keeps
only the desired state: API version, kind and name.

### What was learned

A Namespace gives namespaced resources an administrative boundary and makes
lab queries and cleanup easier. It is not, by itself, a security boundary:
RBAC and NetworkPolicy will be introduced separately.

Declarative manifests should describe intent. Runtime identity and status are
owned by the Kubernetes control plane and should not be copied back into source
manifests.

## Step 3 — Labels and selectors

### What was built

The application resources and Pod templates now use recommended Kubernetes
labels:

| Label | Purpose |
| --- | --- |
| `app.kubernetes.io/name` | Identifies `user-service` or `order-service` |
| `app.kubernetes.io/component` | Describes both services as backend components |
| `app.kubernetes.io/part-of` | Groups the resources under `k8s-java-lab` |

Deployments and Services select Pods by `app.kubernetes.io/name`.

### Commands used

```bash
kubectl apply --dry-run=client -f k8s/sprint-1/
kubectl get all -n k8s-java-lab --show-labels
kubectl get pods -n k8s-java-lab \
  -l app.kubernetes.io/name=user-service
```

### What was learned

Labels describe and group objects. Selectors create relationships between
objects. A Service routes to Pods whose labels match its selector; it does not
route to a Deployment directly.

The selector of an existing Deployment is immutable. Changing the label scheme
can therefore require recreating that Deployment in this disposable lab. In a
production migration, the rollout and compatibility strategy must be planned.

## Step 4 — Order Service networking

### What was built

Order Service now has its own ClusterIP Service. It selects Order Pods through
`app.kubernetes.io/name: order-service` and exposes port `8080` inside the
cluster.

User Service remains internal. Order Service calls it through the stable
Kubernetes DNS endpoint `http://user-service:8080`.

### Commands used

```bash
kubectl apply --dry-run=client -f k8s/sprint-1/
kubectl apply -f k8s/sprint-1/order-service-service.yaml
kubectl get service order-service -n k8s-java-lab
kubectl get endpointslice -n k8s-java-lab \
  -l kubernetes.io/service-name=order-service
kubectl port-forward -n k8s-java-lab service/order-service 8080:8080
curl http://localhost:8080/orders/1001/user
```

### Observation

The request returned Alice through Order Service. This validates the complete
application path:

```text
Local client
  -> port-forward
  -> order-service:8080
  -> Order Pod
  -> user-service:8080
  -> User Pod
```

### What this proves

- A ClusterIP gives a workload a stable virtual address and DNS name.
- EndpointSlices reveal the ready Pod endpoints selected by a Service.
- `port-forward` is a temporary debugging path, not a production ingress
  strategy.
- Service discovery removes the need for Order Service to know individual User
  Pod IP addresses.

## Current state

- [x] Prerequisites are documented.
- [x] Both applications have focused HTTP tests.
- [x] JAR and container image builds are reproducible from source.
- [x] Resources are isolated in `k8s-java-lab`.
- [x] Resources use consistent labels and selectors.
- [x] Both applications have internal ClusterIP Services.
- [x] The Order-to-User request path has been demonstrated.
- [ ] Local images are loaded into Kind automatically.
- [ ] Cluster setup and teardown are automated.
- [ ] The entire workflow is validated from a clean cluster.

## Next step

Load the two local images into Kind explicitly, verify that every node can use
them and document the difference between the host Docker image store and the
container runtime inside Kind nodes.
