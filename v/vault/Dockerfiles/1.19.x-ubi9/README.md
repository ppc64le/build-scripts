## To build a Dockerfile : 
$ docker build -t vault-ppc64le:v1.19.5 .

## Running Vault for Development
$ docker run --cap-add=IPC_LOCK -d --name=dev-vault hashicorp/vault

This runs a completely in-memory Vault server, which is useful for development but should not be used in production.

## Running Vault in Server Mode for Development
$ docker run --cap-add=IPC_LOCK -e 'VAULT_LOCAL_CONFIG={"storage": {"file": {"path": "/vault/file"}}, "listener": [{"tcp": { "address": "0.0.0.0:8200", "tls_disable": true}}], "default_lease_ttl": "168h", "max_lease_ttl": "720h", "ui": true}' -p 8200:8200 hashicorp/vault server

This runs a Vault server with TLS disabled, the file storage backend at path /vault/file and a default secret lease duration of one week and a maximum of 30 days. Disabling TLS and using the file storage backend are not recommended for production use.

Note the --cap-add=IPC_LOCK: this is required in order for Vault to lock memory, which prevents it from being swapped to disk. This is highly recommended. In a non-development environment, if you do not wish to use this functionality, you must add "disable_mlock: true" to the configuration information.
