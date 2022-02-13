#!/bin/bash

set -e

echo "CHOWNER, running in $2, using reference=$1"

MYUID=$(stat --format=%u $1)
MYGID=$(stat --format=%g $1)

echo "UID=$MYUID"
echo "GID=$MYGID"

find $2 ! -uid $MYUID -exec chown -h -v $MYUID:$MYGID {} \;

