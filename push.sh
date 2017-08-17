#!/bin/sh

set -e # exit on error

cd `dirname $0`
source .default.sh

appname="cf-ssh-chisel-$USER"

# Generate a key to identify the server (if one doesn't already exist)
# TODO: put all generated files (this and id_rsa.pub) into a single directory
if [ ! -r ssh_host_rsa_key ]; then
  ssh-keygen -t rsa -f ssh_host_rsa_key -N '' -C "chisel-ssh identity for $appname"
  echo '[localhost]:$CHISEL_LOCAL_PORT' `cat ssh_host_rsa_key.pub` >> ~/.ssh/known_hosts
fi

if [ ! -r id_rsa.pub ]; then
  cp ~/.ssh/id_rsa.pub .
fi

if ! grep -q 'Host chisel' ~/.ssh/config; then
cat <<_EOF_

You might want to add this entry to ~/.ssh/config. Note that the config file is
position-sensitive, so this needs to be added before the 'Host *' entry if you
have one.

Host chisel
    ForwardAgent yes
    HostName localhost
    Port $CHISEL_LOCAL_PORT
    User vcap
    Compression yes
_EOF_
fi

cf push -t 180 $appname & # -t: maximum number of seconds to wait for app to start

export GOPATH=$(echo ${PWD%src/github.com/jpillora/chisel})
go build

wait

./tunnel

# vi: expandtab sw=2 ts=2
