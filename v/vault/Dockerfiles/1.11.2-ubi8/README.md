Docker build command: docker build -t ppc64le/vault .

Docker run command:
    Development mode:
        docker run --cap-add=IPC_LOCK -d --name=dev-vault ppc64le/vault

        Server mode:
        docker run --cap-add=IPC_LOCK -e 'VAULT_LOCAL_CONFIG={"backend": {"file": {"path": "/vault/file"}}, "default_lease_ttl": "168h", "max_lease_ttl": "720h"}' ppc64le/vault server

