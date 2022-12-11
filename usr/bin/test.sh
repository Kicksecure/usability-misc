#!/bin/sh

set -x
su -c "apt-get update -y"
exit $?
