# Build CockroachDB v19.2.2

Please find the instructions to build v19.2.2 release of CockroachDB and to execute the
community tests inside a UBI/RHEL 7.6 container and on RHEL 7.6 host below. Due to resource
limitations imposed inside a container, to have better results of test execution, it is
recommended to run the build/test directly on the host instead of the container.

## UBI/RHEL 7.6 container

To run the container so that the build script and patches are available inside it, execute:

```
# docker container run -it -v `pwd`:/v19.2.2 --workdir /v19.2.2 --name ubi7.6_cockroach19.2.2 registry.access.redhat.com/ubi7/ubi:7.6 /bin/bash
```

OR

```
# docker container run -it -v `pwd`:/v19.2.2 --workdir /v19.2.2 --name rhel7.6_cockroach19.2.2 registry.access.redhat.com/rhel:7.6 /bin/bash
```

If you face any issue in accessing the contents of /v19.2.2 inside the container, please
try deleting the container and adding `--privileged=true` option to the run command.

Enable execute permissions for the build script and run it as:

```
# chmod +x cockroachdb_ubi7.6.sh
# ./cockroachdb_ubi7.6.sh
```

## RHEL 7.6 host

In order to build CockroachDB, please copy the contents of current directory to a directory
on the build machine. Please ensure that build script and patches directory are sibblings on
the build machine.

Enable execute permissions for the build script and run it as:

```
# chmod +x cockroachdb_ubi7.6.sh
# ./cockroachdb_ubi7.6.sh
```
