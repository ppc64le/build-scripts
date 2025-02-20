# Build CockroachDB v20.2.17-oss

Please find the instructions to build v20.2.17 release of CockroachDB and to execute the
community tests inside a UBI8 container below.

## UBI8 container

To run the container so that the build script and patches are available inside it, execute:

```
# docker container run -it -v `pwd`:/v20.2.17-oss --workdir /v20.2.17-oss --name ubi8_cockroach20.2.17-oss registry.access.redhat.com/ubi8/ubi:latest /bin/bash
```

If you face any issue in accessing the contents of /v20.2.17-oss inside the container, please
try deleting the container and adding `--privileged=true` option to the run command.

Enable execute permissions for the build script and run it as:

```
# chmod +x cockroachdb_ubi8.sh
# ./cockroachdb_ubi8.sh
```

# Known issues

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

2. The tests in the following packages fail due to floating point precision issues (rounding off
differences) and floating point arithmetic differences between P and X. Zen does not use floating
point values and the community agreed that this does not affect functionality, so ignoring these
failures.

pkg/ccl/logictestccl
pkg/geo
pkg/geo/geogfn
pkg/geo/geographiclib
pkg/geo/geoindex
pkg/geo/geomfn
pkg/sql/logictest
pkg/sql/opt/exec/execbuilder
pkg/sql/sem/tree
pkg/sql/sem/tree/eval_test

References:
https://github.com/cockroachdb/cockroach/issues/72225
https://github.com/cockroachdb/cockroach/issues/72226
https://github.com/cockroachdb/cockroach/issues/72228

3. Tests in the following packages fail due to platform dependent filenames in the stack traces,
which has no functional impact. So, ignoring these failures.

pkg/sql
pkg/util/log

References:
https://github.com/cockroachdb/cockroach/issues/72227
https://github.com/cockroachdb/cockroach/issues/72284

