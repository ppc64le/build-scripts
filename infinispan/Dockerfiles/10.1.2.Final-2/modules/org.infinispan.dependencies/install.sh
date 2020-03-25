#!/bin/bash
set -e

# Remove dnf and rpm files as package manager not required at runtime
rm -rf /var/lib/rpm /var/lib/dnf
