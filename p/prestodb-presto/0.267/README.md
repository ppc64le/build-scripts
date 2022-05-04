# Pre-requisites

1. This build-script is validated in non-root mode on RHEL 8.3 VM. The tests for
presto-prometheus use `docker` and run containers. So, `docker` must be installed.
2. The VM needs to have access to the codeready-builder repo which is enabled by
the script for installing libstdc++-static package, needed for building libsnappyjava.so.

The document related to issues seen with presto 0.236 test execution applies to 0.267 as
well with minor deviations in dependency versions, etc and a couple of additional issues
as mentioned above.
