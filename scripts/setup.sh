#!/usr/bin/env bash

set -Eeuo pipefail
readonly cluster_name="k8s-java-lab"
readonly expected_context="kind-${cluster_name}"

script_dir="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)"
readonly script_dir

repo_root="$(
  cd -- "${script_dir}/.."
  pwd
)"
readonly repo_root

printf 'Repository root: %s\n\n' "$repo_root"

required_paths=(
  "${repo_root}/kind-config.yaml"
  "${repo_root}/docker-compose.yml"
  "${repo_root}/k8s/sprint-1"
)

printf 'Checking repository files\n'

for required_path in "${required_paths[@]}"; do
  relative_path="${required_path#"${repo_root}/"}"

  if [[ -e "$required_path" ]]; then
    printf '      %-30s OK\n' "$relative_path"
  else
    printf '      %-30s MISSING\n' "$relative_path" >&2
    exit 1
  fi
done

printf '\n'

required_commands=(
  docker
  kind
  kubectl
)

printf '[1/4] Checking prerequisites\n'

for command_name in "${required_commands[@]}"; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '      %-18s OK\n' "$command_name"
  else
    printf '      %-18s MISSING\n' "$command_name" >&2
    exit 1
  fi
done


printf '\n[2/4] Checking Docker daemon\n'

if docker info >/dev/null 2>&1; then
  printf '      Docker daemon      OK\n'
else
  printf '      Docker daemon      UNAVAILABLE\n' >&2
  printf 'Start Docker before running this setup.\n' >&2
  exit 1
fi

cluster_exists=false

printf '\n[3/4] Checking Kind cluster\n'

if kind get clusters | grep -Fxq "$cluster_name"; then
  cluster_exists=true
  printf '      %-18s EXISTS\n' "$cluster_name"
else
  printf '      %-18s NOT FOUND\n' "$cluster_name"
  printf '      The cluster will be created by a later setup step.\n'
fi



printf '\n[4/4] Checking Kubernetes context\n'

if [[ "$cluster_exists" == true ]]; then
  if current_context="$(kubectl config current-context 2>/dev/null)"; then
    if [[ "$current_context" == "$expected_context" ]]; then
      printf '      %-18s APPROVED\n' "$current_context"
    else
      printf '      Current context:  %s\n' "$current_context" >&2
      printf '      Expected context: %s\n' "$expected_context" >&2
      printf 'Refusing to continue with an unapproved context.\n' >&2
      exit 1
    fi
  else
    printf '      No current Kubernetes context is configured.\n' >&2
    exit 1
  fi
else
  printf '      Context check      SKIPPED\n'
fi

printf '\nPrerequisites validated.\n'

readonly user_image="k8s-java-lab/user-service:1.0"
readonly order_image="k8s-java-lab/order-service:1.0"

printf '\n[setup 1/4] Building application images\n'

if docker compose --project-directory "$repo_root" build; then
  printf '      Docker Compose build completed.\n'
else
  printf '      Docker Compose build failed.\n' >&2
  exit 1
fi

for image_name in "$user_image" "$order_image"; do
  if docker image inspect "$image_name" >/dev/null 2>&1; then
    printf '      %-40s OK\n' "$image_name"
  else
    printf '      %-40s MISSING\n' "$image_name" >&2
    exit 1
  fi
done

printf '\n[setup 2/4] Ensuring Kind cluster exists\n'

if [[ "$cluster_exists" == true ]]; then
  printf '      %-18s REUSED\n' "$cluster_name"
else
  if kind create cluster \
    --name "$cluster_name" \
    --config "${repo_root}/kind-config.yaml"; then
    cluster_exists=true
    printf '      %-18s CREATED\n' "$cluster_name"
  else
    printf '      Failed to create Kind cluster %s.\n' "$cluster_name" >&2
    exit 1
  fi
fi

if current_context="$(kubectl config current-context 2>/dev/null)"; then
  if [[ "$current_context" != "$expected_context" ]]; then
    printf '      Current context:  %s\n' "$current_context" >&2
    printf '      Expected context: %s\n' "$expected_context" >&2
    exit 1
  fi
else
  printf '      No current Kubernetes context is configured.\n' >&2
  exit 1
fi

printf '\n[setup 3/4] Loading images into Kind\n'

for image_name in "$user_image" "$order_image"; do
  if kind load docker-image \
    "$image_name" \
    --name "$cluster_name"; then
    printf '      %-40s LOADED\n' "$image_name"
  else
    printf '      %-40s FAILED\n' "$image_name" >&2
    exit 1
  fi
done

readonly namespace="k8s-java-lab"
printf '\n[setup 4/4] Deploying Kubernetes resources\n'

if kubectl \
  --context "$expected_context" \
  apply \
  -f "${repo_root}/k8s/sprint-1"; then
  printf '      Kubernetes manifests applied.\n'
else
  printf '      Failed to apply Kubernetes manifests.\n' >&2
  exit 1
fi

deployments=(
  user-service
  order-service
)

for deployment_name in "${deployments[@]}"; do
  printf '      Waiting for deployment/%s\n' "$deployment_name"

  if kubectl \
    --context "$expected_context" \
    rollout status \
    "deployment/${deployment_name}" \
    --namespace "$namespace" \
    --timeout=180s; then
    printf '      deployment/%-24s READY\n' "$deployment_name"
  else
    printf '      deployment/%s did not become ready.\n' \
      "$deployment_name" >&2

    kubectl \
      --context "$expected_context" \
      get pods \
      --namespace "$namespace" \
      --output=wide >&2 || true

    exit 1
  fi
done

printf '\nSetup completed successfully.\n'
printf 'Namespace: %s\n' "$namespace"
printf 'Context:   %s\n' "$expected_context"