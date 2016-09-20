#!/usr/bin/env bash

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

script_dir="$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)"

cd "${script_dir}"

DOCKER_IMG="${DOCKER_IMG:-karlkfi/minitwit}"

COOKIE_JAR="cookies-$(date | md5sum | head -c 10).txt"

CONTAINER_ID="$(docker run -d "${DOCKER_IMG}")"

curl_try (){
	CMD=${1}
	echo "CMD is: " ${CMD}
	i="0"
	while [[ ${i} < 200 ]]; do
		set +o errexit
		STATUS_CODE="$(${CMD})"
		echo "STATUS_CODE is: " ${STATUS_CODE}
		set -o errexit
		if [[ "200" == "${STATUS_CODE}" ]]; then
		       	break
	       	fi 
		i=$[$i+1]
		sleep 2
	done
}


function cleanup {
  rm -f "${COOKIE_JAR}"
  docker rm -f "$CONTAINER_ID"
}
trap cleanup EXIT

CONTAINER_IP="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CONTAINER_ID})"

public='curl -I -s \"http\:\/\/\$\{CONTAINER_IP\}\/public\" | grep \"HTTP\/1.1\" | cut -d' ' -f2)'
curl_try ${public}

USERNAME="$(date | md5sum | head -c 10)"

reg_tst="curl -v -f -X POST --data "username=${USERNAME}&email=test@mailinator.com&password=password&password2=password" "http://${CONTAINER_IP}/register""
curl_try ${reg_tst}

login_tst="curl -v -f -X POST -c "${COOKIE_JAR}" --data "username=${USERNAME}&password=password" "http://${CONTAINER_IP}/login""
curl_try ${login_tst}

MESSAGE="$(date | md5sum | head -c 10)"

msg_tst="curl -v -f -X POST -b "${COOKIE_JAR}" -data "text=secret-test-message" "http://${CONTAINER_IP}/message""
curl_try ${msg_tst}

getmsg_tst="curl -v -f "http://${CONTAINER_IP}/public" | grep -s "${MESSAGE}""
curl_try ${getmsg_tst}

echo "TEST PASSED"
