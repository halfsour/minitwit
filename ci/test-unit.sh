#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

script_dir="$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)"

cd "${script_dir}"

docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app maven:3.3.9-jdk-8-alpine mvn test

echo "TEST PASSED"
