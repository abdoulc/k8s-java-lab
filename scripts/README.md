# Lab scripts

The scripts in this directory automate the local learning environment. They are
intentionally written in Bash so that each operation remains visible and can be
studied independently.

## `setup.sh`

`setup.sh` builds the applications and converges the local Kind environment to
the state described by the Sprint 1 manifests.

### Requirements

- Bash
- Docker with a running daemon
- Docker Compose v2
- Kind
- kubectl

The script can be launched from any directory. It resolves the repository root
from its own location instead of relying on the current working directory.

### Usage

From the repository root:

```bash
bash scripts/setup.sh
```

If the executable bit is preserved by the checkout, it can also be run with:

```bash
./scripts/setup.sh
```

### Workflow

The script first performs read-only preflight checks:

1. Resolve the repository root.
2. Verify `kind-config.yaml`, `docker-compose.yml` and `k8s/sprint-1`.
3. Verify that `docker`, `kind` and `kubectl` are available.
4. Verify that the Docker daemon is reachable.
5. Detect the `k8s-java-lab` Kind cluster.
6. If that cluster already exists, require the current context to be
   `kind-k8s-java-lab`.

It then performs the setup operations:

1. Build and test both multi-stage container images with Docker Compose.
2. Reuse the `k8s-java-lab` cluster or create it from `kind-config.yaml`.
3. Verify the Kubernetes context again after cluster creation.
4. Load both local images into the Kind nodes.
5. Apply every manifest under `k8s/sprint-1` using the explicit approved
   context.
6. Wait up to 180 seconds for each application Deployment to become ready.

### Resources managed

| Resource | Value |
| --- | --- |
| Kind cluster | `k8s-java-lab` |
| kubectl context | `kind-k8s-java-lab` |
| Namespace | `k8s-java-lab` |
| User image | `k8s-java-lab/user-service:1.0` |
| Order image | `k8s-java-lab/order-service:1.0` |
| Manifests | `k8s/sprint-1` |

### Safety properties

- Bash strict mode stops on errors, unset variables and failed pipelines.
- The Kind cluster name is fixed in the script.
- An existing cluster is reused rather than replaced.
- An unexpected current Kubernetes context stops the script.
- Every mutating `kubectl` command receives `--context kind-k8s-java-lab`
  explicitly.
- Rollout waits are bounded by a timeout.
- An unsuccessful rollout prints the current Pods before exiting.

The script is intended for the local Kind lab. It must not be generalized to
another cluster by changing names casually: the fixed names are part of its
safety boundary.

### Idempotence

Running the script again should:

- rebuild only changed Docker layers;
- reuse the existing Kind cluster;
- reload the expected image tags;
- apply the same desired Kubernetes state;
- wait for the current Deployments.

Idempotence does not mean that every operation is skipped. It means that a
second successful run converges to the same intended state without creating a
second cluster or duplicate Kubernetes resources.

### Expected completion

```text
Setup completed successfully.
Namespace: k8s-java-lab
Context:   kind-k8s-java-lab
```

Check the resulting workloads with:

```bash
kubectl --context kind-k8s-java-lab \
  get pods \
  --namespace k8s-java-lab \
  --output wide
```

### Troubleshooting

#### A required command is missing

Install the command reported as `MISSING` and make sure it is available on the
Bash `PATH`.

#### Docker daemon is unavailable

Start Docker Desktop or the local Docker daemon, then verify:

```bash
docker info
```

#### The Kubernetes context is refused

Inspect the current context and the available contexts:

```bash
kubectl config current-context
kubectl config get-contexts
```

Do not bypass the check when another cluster is selected. Explicitly select the
lab context only if it belongs to the expected local Kind cluster:

```bash
kubectl config use-context kind-k8s-java-lab
```

#### A Pod does not become ready

Inspect the Pods and recent events:

```bash
kubectl --context kind-k8s-java-lab \
  get pods \
  --namespace k8s-java-lab \
  --output wide

kubectl --context kind-k8s-java-lab \
  get events \
  --namespace k8s-java-lab \
  --sort-by=.lastTimestamp
```

Then describe the failing Pod and inspect its logs:

```bash
kubectl --context kind-k8s-java-lab \
  describe pod POD_NAME \
  --namespace k8s-java-lab

kubectl --context kind-k8s-java-lab \
  logs POD_NAME \
  --namespace k8s-java-lab
```

### Current validation status

The setup has been exercised against an existing `k8s-java-lab` cluster. The
complete `cluster absent -> CREATED -> deployed` path will be validated after
`destroy.sh` is implemented, so the lab can be removed and recreated safely.

## `destroy.sh`

`destroy.sh` is the next script in the sprint. Until it is implemented and
reviewed, remove the cluster only with an explicit, carefully checked Kind
command.
