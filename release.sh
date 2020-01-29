#!/bin/bash
set -e

app=$1

if [ -z "${app}" ]; then
  echo "This script requires an application to build"
  exit 1
fi

case "${app}" in
  grapevine)
    tarball="grapevine.tar.gz"
    ;;

  socket)
    tarball="grapevine_socket.tar.gz"
    ;;

  telnet)
    tarball="telnet.tar.gz"
    ;;
esac

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

top_dir=`pwd`
tmp_dir="${top_dir}/tmp"

rm -rf ${tmp_dir}/build
mkdir -p ${tmp_dir}/build
branch=`git rev-parse --abbrev-ref HEAD`
git archive --format=tar ${branch} | tar x -C ${tmp_dir}/build/
cd ${tmp_dir}/build/apps

docker_image=grapevine_${app}

docker build -f ${app}/Dockerfile.releaser -t ${docker_image}:releaser .

docker run -ti --name ${docker_image}_releaser_${DOCKER_UUID} ${docker_image}:releaser /bin/true
docker cp ${docker_image}_releaser_${DOCKER_UUID}:/opt/${tarball} ${tmp_dir}
docker rm ${docker_image}_releaser_${DOCKER_UUID}
