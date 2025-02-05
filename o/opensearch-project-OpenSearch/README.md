### NOTE
The tests require Docker Environment to execute. Please install Docker before running tests.
### Steps to Install docker for ubi 9.3 container
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io -y
sudo systemctl enable docker
sudo systemctl start docker

## Build OpenSearch Container (Version 2.18.0)

This guide outlines the steps required to build the OpenSearch container for version 2.18.0. Follow these instructions carefully to ensure a smooth build process.

### 1. **Install Required Dependencies**
Ensure that the following packages are installed on your system:
yum install -y git gcc gcc-c++ patch make java-21-openjdk-devel python39 python3-devel bzip2-devel zlib-devel openssl-devel

### 2. Clone the OpenSearch Build Repository
git clone https://github.com/opensearch-project/opensearch-build
cd opensearch-build , git checkout 2.18.0

### 3. Install Pyenv and Python Dependencies
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
export PYENV_ROOT="$HOME/.pyenv"
ln -s /usr/bin/pip3 /usr/bin/pip
pip install pipenv
python3 -m pipenv --python /usr/bin/python3.9

### 4. Generate the OpenSearch Tarball , Note: This command only builds the OpenSearch core and does not build any plugins. You need to build the plugins separately.
./build.sh manifests/2.18.0/opensearch-2.18.0.yml -s -c OpenSearch

### 5. Build All Plugins
Build all the plugins listed in the manifests/2.18.0/opensearch-2.18.0.yml file using the -c flag. This ensures that all necessary plugins are included in the build process.

### 6. Extract Tarballs and Prepare Plugin Folders
After generating the zip in Step 4, unzip it and create folders for each plugin inside the following directory: /opensearch-build/tar/builds/opensearch/dist/opensearch-2.18.0-SNAPSHOT/plugins. For reference, use the x86 tarball to create plugin folders. Then, untar the tar files for each plugin into their respective folders.

### 7. Create a New Tarball 
/opensearch-build/tar/builds/opensearch/dist/opensearch-2.18.0-SNAPSHOT

### 8. Prepare Docker Files
Ensure the following files are in place within the opensearch-build/docker/release/dockerfiles directory:
- opensearch-min-2.18.0-SNAPSHOT-linux-ppc64le.tar.gz (generated in Step 7)
- esnode-key.pem
- esnode.pem
- kirk-key.pem
- kirk.pem
- root-ca.pem
### Steps to Generate .pem Files:
Create a Container from opensearchproject/opensearch:2.18.0 image on an x86 machine.
Generate the Required .pem Files by following the Refreshing demo certificates guide. https://github.com/opensearch-project/security/blob/2b5a811de599f7c7fc2ca2b9246e57fd6cfaf33b/DEVELOPER_GUIDE.md#refreshing-demo-certificates
Copy the .pem Files into the /opensearch-build/docker/release/dockerfiles folder.

### Additional required files can be copied from the x86 tarball:
# note: wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.18.0/opensearch-2.18.0-linux-x64.tar.gz
- opensearch-docker-entrypoint-2.x.sh
- performance-analyzer.properties
- opensearch-security
- plugin-stats-metadata
- opensearch.yml
- log4j2.properties
- To resolve the "opensearch-security initialization" issue, copy the necessary configuration files from the config/opensearch-security into a folder named opensearch-build/docker/release/dockerfilessecurity-config.

### 9. Build the Docker Image
use opensearch.al2.dockerfile

