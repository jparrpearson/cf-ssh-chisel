#!/bin/sh

set -e

cd `dirname $0`

for f in `egrep -v '^#' .gitignore`; do
    if echo $f | egrep -q '^/|\.\.'; then
        echo "Ignoring dangerous .gitignore entry $f"
    else
        echo Removing $f
        rm -f $f
    fi
done
