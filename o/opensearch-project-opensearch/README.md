### NOTE
The tests require Docker Environment to execute. Please install Docker before running tests.
### Docker Installation steps (UBI 9.3)
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io -y
sudo systemctl enable docker
sudo systemctl start docker

### To build the Docker image for OpenSearch with a specific version and build date, use the following command:
docker build \
  --build-arg VERSION=2.19.2 \
  --build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --no-cache \
  -t opensearch:2.19.2-ppc64le \
  -f Dockerfile .
