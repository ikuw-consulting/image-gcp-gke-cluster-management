#!/usr/bin/env bats
# Behaviour tests for the leaf cluster-* commands and the k wrapper,
# with kubectl / gcloud / tool binaries mocked onto PATH.

SCRIPTS_DIR="$(cd "${BATS_TEST_DIRNAME}/../scripts" && pwd)"

setup() {
  mkdir -p "${BATS_TEST_TMPDIR}/bin"

  # Mock kubectl: echo args so calls are observable.
  cat > "${BATS_TEST_TMPDIR}/bin/kubectl" <<'MOCK'
#!/usr/bin/env bash
echo "kubectl $*"
MOCK
  chmod +x "${BATS_TEST_TMPDIR}/bin/kubectl"

  # Mock gcloud: log every call, exit code driven by REGION_EXIT/ZONE_EXIT.
  cat > "${BATS_TEST_TMPDIR}/bin/gcloud" <<MOCK
#!/usr/bin/env bash
echo "gcloud \$*" >> "${BATS_TEST_TMPDIR}/gcloud.log"
case "\$*" in
  *--region*) exit "\${REGION_EXIT:-0}" ;;
  *--zone*)   exit "\${ZONE_EXIT:-0}" ;;
esac
exit 0
MOCK
  chmod +x "${BATS_TEST_TMPDIR}/bin/gcloud"

  # Version-only tool mocks for validate-image.
  for tool in age gke-gcloud-auth-plugin yq; do
    cat > "${BATS_TEST_TMPDIR}/bin/${tool}" <<'MOCK'
#!/usr/bin/env bash
echo "mock version"
MOCK
    chmod +x "${BATS_TEST_TMPDIR}/bin/${tool}"
  done

  export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
}

# ---------------------------------------------------------------- validate-image

@test "cluster-validate-image: passes when all tools present" {
  run bash "${SCRIPTS_DIR}/cluster-validate-image"
  echo "OUTPUT: ${output}"
  [[ "${status}" -eq 0 ]]
}

# PATH is pinned to the mock bin (minus gcloud) so the tool is genuinely
# absent regardless of what CI runners ship. The script bails at the first
# `command -v` miss before exec'ing any mock, so bash is invoked by absolute
# path and no mock shebang needs resolving.
@test "cluster-validate-image: fails when a required tool is missing" {
  rm "${BATS_TEST_TMPDIR}/bin/gcloud"
  run env "PATH=${BATS_TEST_TMPDIR}/bin" "$(command -v bash)" "${SCRIPTS_DIR}/cluster-validate-image"
  [[ "${status}" -ne 0 ]]
}

# ------------------------------------------------------------- setup-credentials

@test "cluster-setup-credentials: fails without GCP_PROJECT_ID" {
  unset GCP_PROJECT_ID GKE_CLUSTER_NAME GKE_CLUSTER_LOCATION
  run bash "${SCRIPTS_DIR}/cluster-setup-credentials"
  [[ "${status}" -ne 0 ]]
  [[ "${output}" == *"GCP_PROJECT_ID is required"* ]]
}

@test "cluster-setup-credentials: fails without GKE_CLUSTER_NAME" {
  export GCP_PROJECT_ID=proj
  unset GKE_CLUSTER_NAME GKE_CLUSTER_LOCATION
  run bash "${SCRIPTS_DIR}/cluster-setup-credentials"
  [[ "${status}" -ne 0 ]]
  [[ "${output}" == *"GKE_CLUSTER_NAME is required"* ]]
}

@test "cluster-setup-credentials: fails without GKE_CLUSTER_LOCATION" {
  export GCP_PROJECT_ID=proj GKE_CLUSTER_NAME=cl
  unset GKE_CLUSTER_LOCATION
  run bash "${SCRIPTS_DIR}/cluster-setup-credentials"
  [[ "${status}" -ne 0 ]]
  [[ "${output}" == *"GKE_CLUSTER_LOCATION is required"* ]]
}

@test "cluster-setup-credentials: regional lookup succeeds, no zonal fallback" {
  export GCP_PROJECT_ID=proj GKE_CLUSTER_NAME=cl GKE_CLUSTER_LOCATION=loc
  export REGION_EXIT=0
  run bash "${SCRIPTS_DIR}/cluster-setup-credentials"
  [[ "${status}" -eq 0 ]]
  grep -q -- "--region loc" "${BATS_TEST_TMPDIR}/gcloud.log"
  ! grep -q -- "--zone" "${BATS_TEST_TMPDIR}/gcloud.log"
}

@test "cluster-setup-credentials: falls back to zonal when regional fails" {
  export GCP_PROJECT_ID=proj GKE_CLUSTER_NAME=cl GKE_CLUSTER_LOCATION=loc
  export REGION_EXIT=1 ZONE_EXIT=0
  run bash "${SCRIPTS_DIR}/cluster-setup-credentials"
  [[ "${status}" -eq 0 ]]
  grep -q -- "--region loc" "${BATS_TEST_TMPDIR}/gcloud.log"
  grep -q -- "--zone loc" "${BATS_TEST_TMPDIR}/gcloud.log"
}

@test "cluster-setup-credentials: fails when both regional and zonal fail" {
  export GCP_PROJECT_ID=proj GKE_CLUSTER_NAME=cl GKE_CLUSTER_LOCATION=loc
  export REGION_EXIT=1 ZONE_EXIT=1
  run bash "${SCRIPTS_DIR}/cluster-setup-credentials"
  [[ "${status}" -ne 0 ]]
}

# ---------------------------------------------------------------------- apply

@test "cluster-apply: fails 66 when manifest path missing" {
  run bash "${SCRIPTS_DIR}/cluster-apply" "${BATS_TEST_TMPDIR}/nope"
  [[ "${status}" -eq 66 ]]
  [[ "${output}" == *"does not exist"* ]]
}

@test "cluster-apply: applies server-side with the kaptain field manager" {
  mkdir -p "${BATS_TEST_TMPDIR}/manifests"
  run bash "${SCRIPTS_DIR}/cluster-apply" "${BATS_TEST_TMPDIR}/manifests"
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"apply --server-side --field-manager=kaptain-cluster-seed -f ${BATS_TEST_TMPDIR}/manifests"* ]]
}

@test "cluster-apply: uses CLUSTER_MANIFEST_DIR when no arg given" {
  mkdir -p "${BATS_TEST_TMPDIR}/default-manifests"
  export CLUSTER_MANIFEST_DIR="${BATS_TEST_TMPDIR}/default-manifests"
  run bash "${SCRIPTS_DIR}/cluster-apply"
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"-f ${BATS_TEST_TMPDIR}/default-manifests"* ]]
}

# ----------------------------------------------------------------------- wait

@test "cluster-wait: waits on all deployments without a selector" {
  run bash "${SCRIPTS_DIR}/cluster-wait"
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"wait --for=condition=available --timeout=300s deployment --all-namespaces"* ]]
  [[ "${output}" != *"-l "* ]]
}

@test "cluster-wait: passes a label selector through" {
  run bash "${SCRIPTS_DIR}/cluster-wait" "app=web"
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"-l app=web"* ]]
}

# ------------------------------------------------------------------- list-all

@test "cluster-list-all: queries version, nodes, namespaces and deployments" {
  run bash "${SCRIPTS_DIR}/cluster-list-all"
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"kubectl version"* ]]
  [[ "${output}" == *"kubectl get nodes -o wide"* ]]
  [[ "${output}" == *"kubectl get namespaces"* ]]
  [[ "${output}" == *"kubectl get deployments --all-namespaces"* ]]
}

# --------------------------------------------------------------------------- k

@test "k: passes all args straight through to kubectl" {
  run bash "${SCRIPTS_DIR}/k" get pods -n kube-system
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "kubectl get pods -n kube-system" ]]
}
