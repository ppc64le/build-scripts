OpenSearch Docker Image Build Guide (ppc64le)
NOTE
The tests require a Docker environment to execute.Please install Docker before running the tests.

Docker Installation Steps (UBI 9.3)

Run the following commands:

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker


Verify Docker installation:

docker --version

Building OpenSearch Docker Image (Version 3.3.0 – ppc64le)

Clone and Checkout the Repository
git clone https://github.com/opensearch-project/opensearch-build.git
cd opensearch-build
git checkout 3.3.0

Copy Required Files

Copy the following files into:

opensearch-build/docker/release/dockerfiles/


Dockerfile

opensearch-build.patch

All required snapshot .zip files

Build the Docker Image

Navigate to:

cd opensearch-build/docker/release


Run:

./build-image-single-arch.sh -v 3.3.0 -p opensearch -a ppc64le -f dockerfiles/Dockerfile

Important: Snapshot Files Requirement

If your Dockerfile depends on snapshot plugin builds:

Build the snapshot plugins first.

Copy the generated .zip files into:

opensearch-build/docker/release/dockerfiles/


Few plugins snapshots are copied from the host into the Docker build context and need to build it as:
for eg:
wget https://raw.githubusercontent.com/ppc64le/build-scripts/7ddb950ffe9482a5365ee459bb9756e2f529305d/o/opensearch-project-query-insights/opensearch-project-query-insights_3.3.0.0_ubi_9.6.sh

and run it as:
./opensearch-project-query-insights_3.3.0.0_ubi_9.6.sh --skip-tests

Required Modification in build-image-single-arch.sh

Add the following block inside:

opensearch-build/docker/release/build-image-single-arch.sh

Add After Workspace Creation Section
# Create temp workdirectory
DIR=`Temp_Folder_Create`
Trap_File_Delete_No_Sigchld $DIR
echo New workspace $DIR

# Copy configs
cp -v config/${PRODUCT}/* $DIR/
cp -v ../../config/${PRODUCT_ALT}*.yml $DIR/
cp -v ../../scripts/opensearch-onetime-setup.sh $DIR/

# Copy opensearch-build patch into Docker build context
cp -v dockerfiles/opensearch-build.patch $DIR/
cp -v dockerfiles/opensearch-ml-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-neural-search-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-skills-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-flow-framework-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-security-3.3.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/query-insights-3.3.0.0-SNAPSHOT.zip $DIR/

# Optional (if required)
# cp -v dockerfiles/opensearch-project-k-NN_3.3.0.0_ubi_9.6.sh $DIR/
# chmod +x $DIR/opensearch-project-k-NN_3.3.0.0_ubi_9.6.sh
