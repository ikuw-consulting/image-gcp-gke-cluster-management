#!/usr/bin/env bats
# Static analysis of all scripts

SCRIPTS_DIR="$(cd "${BATS_TEST_DIRNAME}/../scripts" && pwd)"
WORK_DIR="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/${OUTPUT_SUB_PATH:-kaptain-out}/script-standards"

setup() {
  rm -rf "${WORK_DIR}"
  mkdir -p "${WORK_DIR}"
}

@test "all scripts have bash shebang" {
  local failures=()
  for script in "${SCRIPTS_DIR}"/*; do
    first_line=$(head -n1 "${script}")
    if [[ "${first_line}" != "#!/usr/bin/env bash" ]]; then
      failures+=("$(basename "${script}")")
    fi
  done
  if [[ ${#failures[@]} -gt 0 ]]; then
    printf "Missing shebang: %s\n" "${failures[@]}" > "${WORK_DIR}/shebang-failures.txt"
    cat "${WORK_DIR}/shebang-failures.txt"
    return 1
  fi
}

@test "all scripts have set -euo pipefail" {
  local failures=()
  for script in "${SCRIPTS_DIR}"/*; do
    if ! grep -q "set -euo pipefail" "${script}"; then
      failures+=("$(basename "${script}")")
    fi
  done
  if [[ ${#failures[@]} -gt 0 ]]; then
    printf "Missing set -euo pipefail: %s\n" "${failures[@]}" > "${WORK_DIR}/pipefail-failures.txt"
    cat "${WORK_DIR}/pipefail-failures.txt"
    return 1
  fi
}

@test "all scripts are executable" {
  local failures=()
  for script in "${SCRIPTS_DIR}"/*; do
    if [[ ! -x "${script}" ]]; then
      failures+=("$(basename "${script}")")
    fi
  done
  if [[ ${#failures[@]} -gt 0 ]]; then
    printf "Not executable: %s\n" "${failures[@]}" > "${WORK_DIR}/executable-failures.txt"
    cat "${WORK_DIR}/executable-failures.txt"
    return 1
  fi
}

@test "all files end with newline" {
  local failures=()
  for script in "${SCRIPTS_DIR}"/*; do
    if [[ -n "$(tail -c 1 "${script}")" ]]; then
      failures+=("$(basename "${script}")")
    fi
  done
  if [[ ${#failures[@]} -gt 0 ]]; then
    printf "No trailing newline: %s\n" "${failures[@]}" > "${WORK_DIR}/newline-failures.txt"
    cat "${WORK_DIR}/newline-failures.txt"
    return 1
  fi
}
