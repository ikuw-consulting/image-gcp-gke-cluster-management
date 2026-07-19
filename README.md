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

## Runtime Identity

The image provides the numeric non-root user and group `4242:4242`. Following
the Kaptain cluster-management base-image pattern, the generic image remains
root during downstream image assembly. Final consumer images must select
`4242:4242`; workload manifests can then enforce `runAsNonRoot: true` without
relying on a named user that the Kubernetes runtime cannot verify numerically.

## Release Versioning

Published tags use a three-part `C.D.E` shape derived from the embedded
`kubectl` compatibility line. Kaptain keeps the first two parts of
`KUBECTL_VERSION` and increments the image-owned third part. For example,
`KUBECTL_VERSION=1.34.8` produces the `1.34.N` image release series. This moves
new releases off the legacy two-part `1.1` tag without treating that tag as the
start of another two-part series.

## Tests

Run `.github/bin/run-tests.bash` from a Kaptain development environment. The
versioning contract test calls the same provider used by the pinned Kaptain
workflow. Locally, `KAPTAIN_USER_SCRIPTS_BUILD_SCRIPTS_REPO_ROOT` must point to
a compatible `buildon-github-actions` checkout; inside the workflow the test
discovers that checkout through `GITHUB_ACTION_PATH`.

## Cluster Seed Pattern

This image is intentionally separate from the seed manifest repo. The image
contains tools and operational scripts; a cluster repo compiles and supplies the
actual manifests, including vendored CRDs and cluster-scoped controllers.
