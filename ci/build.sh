#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

script_dir="$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)"

cd "${script_dir}"

DOCKER_IMG="${DOCKER_IMG:-karlkfi/minitwit}"

docker build -t ${DOCKER_IMG} .