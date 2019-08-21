#!/bin/bash
set -e

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

mkdir -p tmp/

echo -e "travis_fold:start:docker-build\r"
docker build -f Dockerfile.releaser -t telnet:releaser .
echo -e "\ntravis_fold:end:docker-build\r"

docker run -ti --name telnet_releaser_${DOCKER_UUID} telnet:releaser /bin/true
docker cp telnet_releaser_${DOCKER_UUID}:/opt/telnet.tar.gz tmp/
docker rm telnet_releaser_${DOCKER_UUID}
