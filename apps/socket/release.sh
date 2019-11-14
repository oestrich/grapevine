#!/bin/bash
set -e

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

mkdir -p tmp/

docker build -f Dockerfile.releaser -t grapevine_socket:releaser ../

docker run -ti --name grapevine_socket_releaser_${DOCKER_UUID} grapevine_socket:releaser /bin/true
docker cp grapevine_socket_releaser_${DOCKER_UUID}:/opt/grapevine_socket.tar.gz tmp/
docker rm grapevine_socket_releaser_${DOCKER_UUID}
