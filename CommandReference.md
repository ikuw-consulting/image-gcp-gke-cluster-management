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

Applies YAML manifests from `PATH` using `kubectl apply --server-side` and the
`kaptain-cluster-seed` field manager. When `PATH` is omitted, the command uses
`CLUSTER_MANIFEST_DIR`, defaulting to `/kd/manifests`.

## cluster wait [SELECTOR]

Waits for deployments across all namespaces to become available. When provided,
`SELECTOR` is passed to `kubectl wait` as a label selector.

## cluster list all

Prints a compact cluster inventory.

## k

Thin wrapper around `kubectl`.
