diff --git a/tools/docker-copy.sh b/tools/docker-copy.sh
index 5c1d1a60ce..616d31d560 100755
--- a/tools/docker-copy.sh
+++ b/tools/docker-copy.sh
@@ -38,6 +38,9 @@ function may_copy_into_arch_named_sub_dir() {
       *x86-64*)
         mkdir -p "${DOCKER_WORKING_DIR}/amd64/" && cp -rp "${FILE}" "${DOCKER_WORKING_DIR}/amd64/"
         ;;
+      *PowerPC*)
+        mkdir -p "${DOCKER_WORKING_DIR}/ppc64le/" && cp -rp "${FILE}" "${DOCKER_WORKING_DIR}/ppc64le/"
+        ;;
       *aarch64*)
         mkdir -p "${DOCKER_WORKING_DIR}/arm64/" && cp -rp "${FILE}" "${DOCKER_WORKING_DIR}/arm64/"
         ;;
diff --git a/tools/istio-docker.mk b/tools/istio-docker.mk
index 85df09a1e1..08509fa43d 100644
--- a/tools/istio-docker.mk
+++ b/tools/istio-docker.mk
@@ -27,7 +27,7 @@ docker: docker.all
 # Add new docker targets to the end of the DOCKER_TARGETS list.
 
 DOCKER_TARGETS ?= docker.pilot docker.proxyv2 docker.app docker.app_sidecar_ubuntu_xenial \
-docker.app_sidecar_ubuntu_bionic docker.app_sidecar_ubuntu_focal docker.app_sidecar_debian_9 \
+docker.app_sidecar_ubuntu_bionic docker.app_sidecar_ubuntu_focal \
 docker.app_sidecar_debian_10 docker.app_sidecar_centos_8 docker.app_sidecar_centos_7 \
 docker.istioctl docker.operator docker.install-cni
 
diff --git a/Makefile.core.mk b/Makefile.core.mk
index a7177629c2..8169c3b82b 100644
--- a/Makefile.core.mk
+++ b/Makefile.core.mk
@@ -431,6 +431,8 @@ ${ISTIO_OUT}/release/istioctl-linux-armv7: depend
 	GOOS=linux GOARCH=arm GOARM=7 LDFLAGS=$(RELEASE_LDFLAGS) common/scripts/gobuild.sh $@ ./istioctl/cmd/istioctl
 ${ISTIO_OUT}/release/istioctl-linux-arm64: depend
 	GOOS=linux GOARCH=arm64 LDFLAGS=$(RELEASE_LDFLAGS) common/scripts/gobuild.sh $@ ./istioctl/cmd/istioctl
+${ISTIO_OUT}/release/istioctl-linux-ppc64le: depend
+	GOOS=linux GOARCH=ppc64le LDFLAGS=$(RELEASE_LDFLAGS) common/scripts/gobuild.sh $@ ./istioctl/cmd/istioctl
 ${ISTIO_OUT}/release/istioctl-osx: depend
 	GOOS=darwin GOARCH=amd64 LDFLAGS=$(RELEASE_LDFLAGS) common/scripts/gobuild.sh $@ ./istioctl/cmd/istioctl
 ${ISTIO_OUT}/release/istioctl-osx-arm64: depend
