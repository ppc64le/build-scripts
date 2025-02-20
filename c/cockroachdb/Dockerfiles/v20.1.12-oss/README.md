# Build CockroachDB v20.1.12-oss

Please find the instructions to build v20.1.12 release of CockroachDB and to execute the
community tests inside a UBI8 container below.

## UBI8 container

To run the container so that the build script and patches are available inside it, execute:

```
# docker container run -it -v `pwd`:/v20.1.12-oss --workdir /v20.1.12-oss --name ubi8_cockroach20.1.12-oss registry.access.redhat.com/ubi8/ubi:latest /bin/bash
```

If you face any issue in accessing the contents of /v20.1.12-oss inside the container, please
try deleting the container and adding `--privileged=true` option to the run command.

Enable execute permissions for the build script and run it as:

```
# chmod +x cockroachdb_ubi8.sh
# ./cockroachdb_ubi8.sh
```

# Known issues and workarounds for v20.1.12 oss build

1. Test failure in pkg/cli with "fatal: morestack on g0"

Reference:

https://github.com/cockroachdb/cockroach/issues/62979

https://cockroachdb.slack.com/archives/CP4D9LD5F/p1617255182279400

Workaround:

Patch out thread stack dump feature for ppc64le as a workaround

```
sed -i '/add_definitions(-DOS_LINUX)/d' c-deps/libroach/CMakeLists.txt
sed -i 's/thread stacks only available on Linux\/Glibc/thread stacks unavailable on ppc64le/g' c-deps/libroach/stack_trace.cc
```

