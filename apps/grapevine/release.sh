#!/bin/bash
set -e

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

rm -rf tmp/build
mkdir -p tmp/build
branch=`git rev-parse --abbrev-ref HEAD`
git archive --format=tar ${branch} | tar x -C tmp/build/
cd tmp/build

docker build -f Dockerfile.releaser -t grapevine:releaser .

docker run -ti --name grapevine_releaser_${DOCKER_UUID} grapevine:releaser /bin/true
docker cp grapevine_releaser_${DOCKER_UUID}:/opt/grapevine.tar.gz ../
docker rm grapevine_releaser_${DOCKER_UUID}
