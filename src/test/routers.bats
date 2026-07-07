#!/usr/bin/env bats
# Test the `cluster` dispatcher routes verbs to sibling scripts.
#
# The dispatcher resolves siblings (cluster-welcome, cluster-apply, ...)
# by bare name via PATH, so setup puts the real scripts dir plus a mock
# bin (kubectl et al) on PATH.

SCRIPTS_DIR="$(cd "${BATS_TEST_DIRNAME}/../scripts" && pwd)"

setup() {
  mkdir -p "${BATS_TEST_TMPDIR}/bin"

  # Mock kubectl: echoes its args so list/wait routing is observable.
  cat > "${BATS_TEST_TMPDIR}/bin/kubectl" <<'MOCK'
#!/usr/bin/env bash
echo "kubectl $*"
MOCK
  chmod +x "${BATS_TEST_TMPDIR}/bin/kubectl"

  export PATH="${BATS_TEST_TMPDIR}/bin:${SCRIPTS_DIR}:${PATH}"
}

run_cluster() {
  bash "${SCRIPTS_DIR}/cluster" "$@"
}

@test "cluster: no args defaults to welcome and exits 0" {
  run run_cluster
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"cluster management image"* ]]
}

@test "cluster: welcome exits 0 with command list" {
  run run_cluster welcome
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"cluster validate-image"* ]]
}

@test "cluster: unknown command exits 64 with error" {
  run run_cluster nonexistent
  [[ "${status}" -eq 64 ]]
  [[ "${output}" == *"Unknown cluster command"* ]]
}

@test "cluster: apply routes to cluster-apply (missing path exits 66)" {
  run run_cluster apply "${BATS_TEST_TMPDIR}/does-not-exist"
  [[ "${status}" -eq 66 ]]
  [[ "${output}" == *"does not exist"* ]]
}

@test "cluster: list defaults to 'all' and reaches cluster-list-all" {
  run run_cluster list
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"kubectl get nodes -o wide"* ]]
}

@test "cluster: wait routes to cluster-wait" {
  run run_cluster wait
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"kubectl wait --for=condition=available"* ]]
}
