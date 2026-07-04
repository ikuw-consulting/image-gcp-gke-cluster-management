# Image GCP GKE Cluster Management

A Kaptain cluster-management image for GKE clusters.

This follows the same role as Kaptain's AWS EKS cluster-management image, but is
scoped to Google Cloud and Kubernetes cluster seed operations. It is intended to
be the execution image for cluster seed and maintenance repos.

## Image Contents

The image installs:

- `gcloud` - Google Cloud authentication and GKE credential setup.
- `gke-gcloud-auth-plugin` - kubectl authentication for GKE.
- `kubectl` - Kubernetes API interaction and manifest application.
- `age` - optional decryption of cluster seed secrets.
- `yq` - YAML inspection and scripted validation.

## Main Commands

```bash
cluster validate-image
cluster setup-credentials
cluster apply /path/to/manifests
cluster wait
cluster list all
```

## Environment

`cluster setup-credentials` expects:

- `GCP_PROJECT_ID`
- `GKE_CLUSTER_NAME`
- `GKE_CLUSTER_LOCATION`

`GKE_CLUSTER_LOCATION` may be a region or zone. The command first tries regional
credentials and then zonal credentials.

For non-interactive use, mount or inject Google credentials in the standard
`gcloud` ways, such as `GOOGLE_APPLICATION_CREDENTIALS` or a preconfigured
Cloud SDK config.

## Cluster Seed Pattern

This image is intentionally separate from the seed manifest repo. The image
contains tools and operational scripts; a cluster repo compiles and supplies the
actual manifests, including vendored CRDs and cluster-scoped controllers.
