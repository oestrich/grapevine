#!/bin/bash
set -e

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

mkdir -p tmp/

echo -e "travis_fold:start:docker-build\r"
docker build -f Dockerfile.releaser -t grapevine:releaser .
echo -e "\ntravis_fold:end:docker-build\r"

docker run -ti --name grapevine_releaser_${DOCKER_UUID} grapevine:releaser /bin/true
docker cp grapevine_releaser_${DOCKER_UUID}:/opt/grapevine.tar.gz tmp/
docker rm grapevine_releaser_${DOCKER_UUID}
