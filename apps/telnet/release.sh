#!/bin/bash
set -e

SHA=`git rev-parse HEAD`

if [ -z ${COOKIE+x} ]; then
  COOKIE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
fi

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

mkdir -p tmp/

echo -e "travis_fold:start:docker-build\r"
docker build --build-arg sha=${SHA} --build-arg cookie=${COOKIE} -f Dockerfile.releaser -t telnet:releaser .
echo -e "\ntravis_fold:end:docker-build\r"

docker run -ti --name telnet_releaser_${DOCKER_UUID} telnet:releaser /bin/true
docker cp telnet_releaser_${DOCKER_UUID}:/app/_build/prod/rel/telnet/releases/1.0.0/telnet.tar.gz tmp/
docker rm telnet_releaser_${DOCKER_UUID}
