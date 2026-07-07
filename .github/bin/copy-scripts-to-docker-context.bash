#!/usr/bin/env bash
set -euo pipefail

# preDockerPrepare hook (KaptainPM.yaml).
#
# The Dockerfile builds with src/docker as its context and does
# `COPY scripts/* /kd/bin/`, so the operational scripts that live in
# src/scripts must be staged into <docker-context>/scripts/ before the
# build runs. This copies them into both platform contexts.

mkdir -p "${DOCKER_CONTEXT_SUB_PATH_LINUX_AMD64}/scripts/"
cp src/scripts/* "${DOCKER_CONTEXT_SUB_PATH_LINUX_AMD64}/scripts/"

mkdir -p "${DOCKER_CONTEXT_SUB_PATH_LINUX_ARM64}/scripts/"
cp src/scripts/* "${DOCKER_CONTEXT_SUB_PATH_LINUX_ARM64}/scripts/"
