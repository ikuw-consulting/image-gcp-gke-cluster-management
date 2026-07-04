# Command Reference

## cluster validate-image

Checks that required tools are installed and executable.

## cluster setup-credentials

Runs `gcloud container clusters get-credentials` for the configured GKE cluster.

Required environment:

- `GCP_PROJECT_ID`
- `GKE_CLUSTER_NAME`
- `GKE_CLUSTER_LOCATION`

## cluster apply PATH

Applies YAML manifests from `PATH` using `kubectl apply --server-side`.

## cluster wait

Waits for non-system deployments to become available.

## cluster list all

Prints a compact cluster inventory.

## k

Thin wrapper around `kubectl`.
