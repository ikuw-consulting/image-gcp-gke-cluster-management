#!/usr/bin/env bash
set -euo pipefail

# preTaggingTests hook (KaptainPM.yaml).
#
# Installs the test toolchain if missing, checks every script is
# executable, then runs the BATS suite in src/test.

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPTS_DIR="${REPO_ROOT}/src/scripts"
TEST_DIR="${REPO_ROOT}/src/test"

# Install required tools if not available
apt_updated=""
ensure_installed() {
  local cmd="$1"
  local pkg="${2:-$1}"
  if ! command -v "${cmd}" &>/dev/null; then
    echo "Installing ${pkg}..."
    if [[ -z "${apt_updated}" ]]; then
      sudo apt-get update -qq
      apt_updated="true"
    fi
    sudo apt-get install -y -qq "${pkg}"
  else
    echo "Already installed ${pkg}"
  fi
}

ensure_installed bats bats
ensure_installed shellcheck shellcheck
ensure_installed yq yq

# Pre-flight: all scripts must be executable
echo "Pre-flight: checking executable permissions..."
errors=0
for script in "${SCRIPTS_DIR}"/*; do
  if [[ ! -x "${script}" ]]; then
    echo "  FAIL: $(basename "${script}") is not executable"
    errors=$((errors + 1))
  fi
done
echo "Pre-flight check scan complete."
if [[ ${errors} -gt 0 ]]; then
  echo "${errors} script(s) missing executable permission"
  exit 1
else
  echo "No errors."
fi
echo "  All scripts executable."

# Run BATS tests
echo ""
echo "Running BATS tests..."
bats "${TEST_DIR}/"
