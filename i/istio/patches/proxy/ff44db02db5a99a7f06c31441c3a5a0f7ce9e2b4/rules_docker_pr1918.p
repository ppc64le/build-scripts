diff --git a/WORKSPACE b/WORKSPACE
index c5201d7a..aed4c0c5 100644
--- a/WORKSPACE
+++ b/WORKSPACE
@@ -25,6 +25,13 @@ load(
     "istioapi_dependencies",
 )
 
+# FIXME: temporary code, to use rules_docker from PR#1918 instead of master
+local_repository(
+    name = "io_bazel_rules_docker",
+    path = "/bazel/rules_docker",
+)
+# END FIXME
+
 googletest_repositories()
 
 istioapi_dependencies()
diff --git a/common/scripts/run.sh b/common/scripts/run.sh
index 271fe77a..ae92a98c 100755
--- a/common/scripts/run.sh
+++ b/common/scripts/run.sh
@@ -59,6 +59,8 @@ read -ra DOCKER_RUN_OPTIONS <<< "${DOCKER_RUN_OPTIONS:-}"
     --mount "type=volume,source=go,destination=/go" \
     --mount "type=volume,source=gocache,destination=/gocache" \
-    --mount "type=volume,source=cache,destination=/home/.cache" \
+    --mount "type=bind,source=${BAZEL_WORK_DIR}/cache,destination=${BAZEL_WORK_DIR}/cache" \
+    --mount "type=bind,source=${BAZEL_WORK_DIR}/rules_docker,destination=/bazel/rules_docker" \
+    --env TEST_TMPDIR=${BAZEL_WORK_DIR}/cache/bazel \
     ${CONDITIONAL_HOST_MOUNTS} \
     -w "${MOUNT_DEST}" "${IMG}" "$@"
