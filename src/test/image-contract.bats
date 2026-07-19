#!/usr/bin/env bats
# Build-contract tests for the published management image.

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"

kaptain_version_provider() {
  local strategy="${1}"
  local provider_relative_path
  provider_relative_path="src/scripts/plugins/tag-version-calculation-providers/tag-version-calculation-${strategy}"

  if [[ -n "${KAPTAIN_USER_SCRIPTS_BUILD_SCRIPTS_REPO_ROOT:-}" ]] &&
    [[ -x "${KAPTAIN_USER_SCRIPTS_BUILD_SCRIPTS_REPO_ROOT}/${provider_relative_path}" ]]; then
    printf '%s\n' \
      "${KAPTAIN_USER_SCRIPTS_BUILD_SCRIPTS_REPO_ROOT}/${provider_relative_path}"
    return
  fi

  if [[ -n "${GITHUB_ACTION_PATH:-}" ]] &&
    [[ -x "${GITHUB_ACTION_PATH}/../../scripts/plugins/tag-version-calculation-providers/tag-version-calculation-${strategy}" ]]; then
    printf '%s\n' \
      "${GITHUB_ACTION_PATH}/../../scripts/plugins/tag-version-calculation-providers/tag-version-calculation-${strategy}"
    return
  fi

  return 1
}

@test "annotated 1.1 checkout migrates to a three-part Kubernetes-minor release series" {
  run git -C "${REPO_ROOT}" cat-file -t refs/tags/1.1

  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "tag" ]]

  local strategy provider
  strategy="$(
    yq -r '.spec.global.release.versioning.strategy // "git-auto-closest-highest"' \
      "${REPO_ROOT}/KaptainPM.yaml"
  )"
  provider="$(kaptain_version_provider "${strategy}")"

  export BUILD_PLATFORM=test
  export OUTPUT_SUB_PATH="${BATS_TEST_TMPDIR}/versioning"
  export TAG_VERSION_MAX_PARTS
  export TAG_VERSION_PATTERN_TYPE
  export TAG_VERSION_PREFIX_PARTS
  export TAG_VERSION_SOURCE_SUB_PATH
  export TAG_VERSION_SOURCE_FILE_NAME
  TAG_VERSION_MAX_PARTS="$(
    yq -r '.spec.global.release.versioning.maxParts // "3"' \
      "${REPO_ROOT}/KaptainPM.yaml"
  )"
  TAG_VERSION_PATTERN_TYPE="$(
    yq -r '.spec.global.release.versioning.patternType // "dockerfile-env-kubectl"' \
      "${REPO_ROOT}/KaptainPM.yaml"
  )"
  TAG_VERSION_PREFIX_PARTS="$(
    yq -r '.spec.global.release.versioning.source.prefixParts // ""' \
      "${REPO_ROOT}/KaptainPM.yaml"
  )"
  TAG_VERSION_SOURCE_SUB_PATH="$(
    yq -r '.spec.global.release.versioning.source.subPath // ""' \
      "${REPO_ROOT}/KaptainPM.yaml"
  )"
  TAG_VERSION_SOURCE_FILE_NAME="$(
    yq -r '.spec.global.release.versioning.source.fileName // ""' \
      "${REPO_ROOT}/KaptainPM.yaml"
  )"
  mkdir -p \
    "${OUTPUT_SUB_PATH}/versions-and-naming/tag-version-calculation-provider"

  run bash -c 'cd "$1" && "$2"' _ "${REPO_ROOT}" "${provider}"

  [[ "${status}" -eq 0 ]]

  local kubectl_version calculated_version
  local kubectl_major kubectl_minor ignored
  local calculated_major calculated_minor calculated_patch calculated_extra
  kubectl_version="$(
    awk -F= '$1 == "ENV KUBECTL_VERSION" { print $2 }' \
      "${REPO_ROOT}/src/docker/Dockerfile"
  )"
  calculated_version="$(
    <"${OUTPUT_SUB_PATH}/versions-and-naming/tag-version-calculation-provider/VERSION"
  )"
  IFS=. read -r kubectl_major kubectl_minor ignored <<< "${kubectl_version}"
  IFS=. read -r \
    calculated_major calculated_minor calculated_patch calculated_extra \
    <<< "${calculated_version}"

  [[ "${calculated_major}" == "${kubectl_major}" ]]
  [[ "${calculated_minor}" == "${kubectl_minor}" ]]
  [[ "${calculated_patch}" =~ ^[1-9][0-9]*$ ]]
  [[ -z "${calculated_extra}" ]]
}

@test "base provides numeric non-root identity without selecting it during assembly" {
  local user_id
  user_id="$(
    awk -F= '$1 == "ENV KAPTAIN_USER_ID" { print $2 }' \
      "${REPO_ROOT}/src/docker/Dockerfile"
  )"

  [[ "${user_id}" =~ ^[1-9][0-9]*$ ]]

  grep -Fq 'groupadd -g ${KAPTAIN_USER_ID} kaptain' \
    "${REPO_ROOT}/src/docker/Dockerfile"
  grep -Fq 'useradd -u ${KAPTAIN_USER_ID} -g kaptain' \
    "${REPO_ROOT}/src/docker/Dockerfile"

  run awk '$1 == "USER" { print $2 }' "${REPO_ROOT}/src/docker/Dockerfile"

  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "declared build hooks are present and executable in a clean checkout" {
  local hook

  while IFS= read -r hook; do
    run git -C "${REPO_ROOT}" ls-files --error-unmatch "${hook}"

    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "${hook}" ]]
    [[ -x "${REPO_ROOT}/${hook}" ]]
  done < <(yq -r '.spec.main.hooks[]' "${REPO_ROOT}/KaptainPM.yaml")
}

@test "Docker preparation stages every command for both target platforms" {
  export DOCKER_CONTEXT_SUB_PATH_LINUX_AMD64="${BATS_TEST_TMPDIR}/amd64"
  export DOCKER_CONTEXT_SUB_PATH_LINUX_ARM64="${BATS_TEST_TMPDIR}/arm64"

  run bash -c 'cd "$1" && .github/bin/copy-scripts-to-docker-context.bash' \
    _ "${REPO_ROOT}"

  [[ "${status}" -eq 0 ]]

  local script
  for script in "${REPO_ROOT}"/src/scripts/*; do
    cmp "${script}" \
      "${DOCKER_CONTEXT_SUB_PATH_LINUX_AMD64}/scripts/$(basename "${script}")"
    cmp "${script}" \
      "${DOCKER_CONTEXT_SUB_PATH_LINUX_ARM64}/scripts/$(basename "${script}")"
  done
}

@test "generated Kaptain and Docker-context paths stay out of checkout status" {
  local generated_path

  for generated_path in \
    kaptain-out/probe \
    kaptainpm/probe \
    src/docker/scripts/probe; do
    run git -C "${REPO_ROOT}" check-ignore --quiet "${generated_path}"

    [[ "${status}" -eq 0 ]]
  done
}
