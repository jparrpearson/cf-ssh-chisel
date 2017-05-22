#!/bin/sh

set -e # exit on error

cd `dirname $0`

appname="cf-ssh-chisel-$USER"

# Generate a key to identify the server (if one doesn't already exist)
# TODO: put all generated files (this and id_rsa.pub) into a single directory
if [ ! -r ssh_host_rsa_key ]; then
  ssh-keygen -t rsa -f ssh_host_rsa_key -N '' -C "chisel-ssh identity for $appname"
  echo '[localhost]:5022' `cat ssh_host_rsa_key.pub` >> ~/.ssh/known_hosts
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
    Port 5022
    User vcap
    Compression yes
_EOF_
fi

cf push -t 180 $appname & # -t: maximum number of seconds to wait for app to start

export GOPATH=$(echo ${PWD%src/github.com/jpillora/chisel})
go build

wait

cf app $appname > /dev/null # Make sure app is there

if ! cf app $appname | grep -q running; then
  echo "ERROR: $appname is not running"
  exit 1
fi

url=`cf app $appname | grep urls: | cut -d ' ' -f2`

./chisel client --keepalive 10s https://$url 5022:2022 &

cat <<_EOF_
You can now connect via

ssh vcap@localhost -p 5022

or if you added an entry to ~/.ssh/config:

ssh chisel

_EOF_

# vi: expandtab sw=2 ts=2
