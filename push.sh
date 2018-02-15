#!/bin/bash

set -e # exit on error

cd `dirname $0`
source .default.sh

# See if we're already running...
echo "Checking if $CHISEL_APP_NAME is running"
set +e
out=`cf app $CHISEL_APP_NAME`
rc=$?
set -e
if [ $rc -ne 0 ]; then
  echo "cf app $CHISEL_APP_NAME returned $rc; looking for it via 'cf apps'" >&2
  out=`cf apps`
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "cf apps returned $rc"
    exit $rc
  fi

  lineCount=`echo "$out" | wc -l`
  secondLine=`echo "$out" | head -n2 | tail -n1`
  if [ "$secondLine" != "OK" -o $lineCount -lt 4 ]; then
    echo "unexpected results from 'cf apps':"
    echo
    echo "$out"
    exit 2
  fi

  # At this point, assume things are OK and that the app just isn't installed.
else
  if echo "$out" | grep -q running; then
    echo "$CHISEL_APP_NAME is running; skipping push."
    exit
  fi
fi

# Generate a key to identify the server (if one doesn't already exist)
# TODO: put all generated files (this and id_rsa.pub) into a single directory
if [ ! -r ssh_host_rsa_key ]; then
  ssh-keygen -t rsa -f ssh_host_rsa_key -N '' -C "chisel-ssh identity for $CHISEL_APP_NAME"
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

echo "pushing $CHISEL_APP_NAME to cloud foundry"

cf push -t 180 $@ "$CHISEL_APP_NAME" & # -t: maximum number of seconds to wait for app to start

export GOPATH=$(echo ${PWD%src/github.com/jpillora/chisel})
go build

wait

./tunnel

# vi: expandtab sw=2 ts=2
