#!/bin/sh
# Clean up anything that git has been ignoring

set -e

cd `dirname $0`

git clean -fX
