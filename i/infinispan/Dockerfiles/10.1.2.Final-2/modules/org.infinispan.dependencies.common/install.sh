#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added

# Override default java.config file so that tls is not disabled
cp $ADDED_DIR/java.config /etc/crypto-policies/back-ends/java.config

# Create symlink between bsdtar and tar to enable `oc copy`
ln -s $(command -v bsdtar) /usr/bin/tar
