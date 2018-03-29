Supported Tags:
	0.7.3
	
Docker build command: 
	docker build -t ibmcom/vault-ppc64le:<supported_tag> .

Docker pull command:
	docker pull ibmcom/vault-ppc64le:<supported_tag>

Docker run command: 
    Development mode:
	docker run -d --cap-add=IPC_LOCK -p 8200:8200 --name=dev-vault ibmcom/vault-ppc64le:<supported_tag>
	
	Server mode:
	docker run -d -p 8200:8200 --cap-add=IP C_LOCK -e 'VAULT_LOCAL_CONFIG={"backend": {"file": {"path": "/vault/file"}}, "default_lease_ttl": "168h", "max_lease_ttl": "720h"}' ibmcom/vault-ppc64le:<supported_tag> server
	
	
Please note that <supported_tage> is one of the supported versions from the "Supported Tags" section above and should be replaced as such.
