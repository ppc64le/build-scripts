#!/bin/bash
set -e

# Check if SEARXNG_SECRET is passed to the container
if [ -z "$SEARXNG_SECRET" ]; then
    echo ">> No SEARXNG_SECRET found. Generating a temporary ephemeral secret..."
    # Generate a secure 32-byte hex key using Python
    export SEARXNG_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
else
    echo ">> SEARXNG_SECRET provided by environment."
fi

exec "$@"
