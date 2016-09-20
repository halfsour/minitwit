#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

script_dir="$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)"

cd "${script_dir}"

DOCKER_IMG="${DOCKER_IMG:-karlkfi/minitwit}"

COOKIE_JAR="cookies-$(date | md5sum | head -c 10).txt"

CONTAINER_ID="$(docker run -d "${DOCKER_IMG}")"

function cleanup {
  rm -f "${COOKIE_JAR}"
  docker rm -f "$CONTAINER_ID"
}
trap cleanup EXIT

CONTAINER_IP="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CONTAINER_ID})"

i="0"
while [[ ${i} < 200 ]]; do
  set +o errexit
  STATUS_CODE="$(curl -I -s "http://${CONTAINER_IP}/public" | grep "HTTP/1.1" | cut -d' ' -f2)"
  set -o errexit
  if [[ "200" == "${STATUS_CODE}" ]]; then
    break
  fi
  i=$[$i+1]
  sleep 2
done

STATUS_CODE="$(curl -I -s "http://${CONTAINER_IP}/public" | grep "HTTP/1.1" | cut -d' ' -f2)"

USERNAME="$(date | md5sum | head -c 10)"

curl -v -f -X POST \
  --data "username=${USERNAME}&email=test@mailinator.com&password=password&password2=password" \
  "http://${CONTAINER_IP}/register"

curl -v -f -X POST -c "${COOKIE_JAR}" \
  --data "username=${USERNAME}&password=password" \
  "http://${CONTAINER_IP}/login"

MESSAGE="$(date | md5sum | head -c 10)"

curl -v -f -X POST -b "${COOKIE_JAR}" \
  --data "text=secret-test-message" \
  "http://${CONTAINER_IP}/message"

curl -f "http://${CONTAINER_IP}/public" | grep -s "${MESSAGE}"

echo "TEST PASSED"
