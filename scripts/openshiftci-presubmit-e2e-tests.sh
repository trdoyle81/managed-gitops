#!/usr/bin/env bash

# Exit if some commands fails
set -e

# Show commands in logs
set -x

# Stop port-forwarding when E2E tests are finished.
function finish {
  echo "E2E Test process is finished."

  [ -n "${KUBE_PID}" ] && kill $KUBE_PID && echo "Port-forwarding has been successfully stopped"
  exit
}
trap finish INT EXIT

# Set necessary env variables
export PATH="$PATH:$(pwd)"

# Install Argo CD
make install-argocd-openshift

# Deploy GitOps Service components
# Use Image built by CI, image name is provided as env variable 'CI_IMAGE' by CI
echo "Using Image $CI_IMAGE"
make install-all-k8s IMG=$CI_IMAGE

# Port forwarding is needed by E2E to connect with DB
kubectl port-forward --namespace gitops svc/gitops-postgresql-staging 5432:5432 &
KUBE_PID=$!

# Don't print DB Password in logs.
set +x

# DB Password is required by E2E to connect with DB
export DB_PASS=$(kubectl get -n gitops secret gitops-postgresql-staging -o jsonpath="{.data.postgresql-password}" | base64 --decode)

# Show commands in logs
set -x

# Run E2E tests
make test-e2e
