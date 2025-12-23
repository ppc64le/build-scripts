### NOTE
Tests must be run as a non-root user and require a Docker environment. Please ensure Docker is installed and running before executing the tests.

### Steps to Install docker for ubi 9.6 container
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io -y
sudo systemctl enable docker
sudo systemctl start docker

### The Gradle task server:internalClusterTest has been commented out in the test suite, as it requires approximately 2–3 hours to complete. You can run this test separately if needed using the following command:
./gradlew server:internalClusterTest \
  --max-workers=2 \
  --no-daemon \
  -Dtests.security.manager=false \
  -Dorg.gradle.jvmargs="-Xmx2g --enable-native-access=ALL-UNNAMED"

### Example output:
BUILD SUCCESSFUL in 2h 7m 18s
66 actionable tasks: 1 executed, 65 up-to-date


### The Gradle task server:test may show two failing tests due to the security manager being enabled. You can re-run these individual tests with the security manager disabled using the following commands:
./gradlew :server:test \
  --tests "org.opensearch.ratelimitting.admissioncontrol.AdmissionControlSingleNodeTests.testAdmissionControlRejectionMonitorOnlyMode" \
  -Dtests.security.manager=false

./gradlew :server:test \
  --tests "org.opensearch.ratelimitting.admissioncontrol.AdmissionControlSingleNodeTests.testAdmissionControlRejectionEnforcedMode" \
  -Dtests.security.manager=false

### plugins:ingestion-kafka:internalClusterTest
This task requires the Docker image confluentinc/cp-kafka:6.2.1, which is not available for ppc64le.You need to build this image locally before running the test.

### plugins:ingestion-kinesis:internalClusterTest
This task requires the Docker image localstack/localstack:latest, which is not available for ppc64le.You need to build this image locally before running the test.