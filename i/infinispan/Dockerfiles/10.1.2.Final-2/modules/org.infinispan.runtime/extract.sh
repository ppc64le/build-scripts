#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
SERVER_ROOT=/opt/infinispan

mkdir -p $SERVER_ROOT
cd $SERVER_ROOT
bsdtar --strip-components=1 -xvf /tmp/artifacts/server.zip

cp -r /tmp/artifacts/config-generator.jar $ADDED_DIR/bin/* $SERVER_ROOT/bin
rm $SERVER_ROOT/server/conf/infinispan-local.xml

chown -R 185 /opt
chmod -R g+rwX $SERVER_ROOT
