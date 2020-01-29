#!/bin/bash

set -e

# Include the environment if available
if [ -f ".deploy.env.sh" ]; then
  . .deploy.env.sh
fi

if [ -z "${HOST}" ]; then
  echo '${HOST} MUST be set in order to run this script'
  exit 1
fi

app=$1

if [ -z "${app}" ]; then
  echo "This script requires an application to deploy"
  exit 1
fi

function migrate_grapevine() {
  ssh deploy@${HOST} './grapevine/bin/grapevine eval "Grapevine.ReleaseTasks.migrate()"'
}

case "${app}" in
  grapevine)
    tarball="grapevine.tar.gz"
    folder="grapevine"
    systemd_app="grapevine"

    extra="migrate_grapevine"
    ;;

  socket)
    tarball="grapevine_socket.tar.gz"
    folder="grapevine_socket"
    systemd_app="grapevine_socket"
    ;;

  telnet)
    tarball="telnet.tar.gz"
    folder="telnet"
    systemd_app="telnet"
    ;;
esac

./release.sh ${app}

scp tmp/${tarball} deploy@${HOST}:

ssh deploy@${HOST} "sudo systemctl stop ${systemd_app}"
ssh deploy@${HOST} "tar xzf ${tarball} -C ${folder}"

if [ -n "${extra}" ]; then
  ${extra}
fi

ssh deploy@${HOST} "sudo systemctl start ${systemd_app}"
