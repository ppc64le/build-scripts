# Build CockroachDB v19.1.8

Please find the instructions to build v19.1.8 release of CockroachDB and to execute the
community tests inside a UBI7/RHEL7.6 container below.

## UBI7/RHEL7.6 container

To run the container so that the build script and patches are available inside it, execute:

```
# docker container run -it -v `pwd`:/v19.1.8 --workdir /v19.1.8 --name ubi7_cockroach19.1.8-oss registry.access.redhat.com/ubi7/ubi:latest /bin/bash
```

OR

```
# docker container run -it -v `pwd`:/v19.1.8 --workdir /v19.1.8 --name rhel7.6_cockroach19.1.8-oss registry.access.redhat.com/rhel:7.6 /bin/bash
```

If you face any issue in accessing the contents of /v19.1.8 inside the container, please
try deleting the container and adding `--privileged=true` option to the run command.

Enable execute permissions for the build script and run it as:

```
# chmod +x cockroachdb_ubi7.sh
# ./cockroachdb_ubi7.sh
```
