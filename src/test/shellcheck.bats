#!/usr/bin/env bats
# Run shellcheck on all scripts

SCRIPTS_DIR="$(cd "${BATS_TEST_DIRNAME}/../scripts" && pwd)"
WORK_DIR="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/${OUTPUT_SUB_PATH:-kaptain-out}/shellcheck"

setup() {
  rm -rf "${WORK_DIR}"
  mkdir -p "${WORK_DIR}"
}

@test "all scripts pass shellcheck" {
  local enables=(
    --external-sources
    --enable=require-variable-braces
    --enable=require-double-brackets
    --enable=avoid-nullary-conditions
    --enable=check-unassigned-uppercase
    --enable=deprecate-which
  )
  local failures=()
  for script in "${SCRIPTS_DIR}"/*; do
    if ! shellcheck "${enables[@]}" "${script}" > "${WORK_DIR}/$(basename "${script}").out" 2>&1; then
      failures+=("$(basename "${script}")")
    fi
  done
  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "Shellcheck failures:"
    for f in "${failures[@]}"; do
      echo "--- ${f} ---"
      cat "${WORK_DIR}/${f}.out"
      echo ""
    done
    return 1
  fi
}
