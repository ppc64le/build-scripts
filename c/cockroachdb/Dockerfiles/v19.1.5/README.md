# Build CockroachDB v19.1.5

Please find the instructions to build v19.1.5 release of CockroachDB and to execute
the community tests inside a UBI 7.6 container and inside a debian 9.8-slim container
below.

## UBI 7.6 container

To run the container so that the build script and patches are available inside it, execute:

```
# docker container run -it -v `pwd`:/v19.1.5 --workdir /v19.1.5 --name ubi7.6_cockroach19.1.5 registry.access.redhat.com/ubi7/ubi:7.6 /bin/bash
```

Then execute the build script as:

```
# chmod +x cockroachdb_ubi7.6.sh
# ./cockroachdb_ubi7.6.sh
```

## Debian 9.8 slim container

To run the container so that the build script and patches are available inside it, execute:

```
# docker container run -it -v `pwd`:/v19.1.5 --workdir /v19.1.5 --name debian9.8slim_cockroach19.1.5 debian:9.8-slim /bin/bash
```

Then execute the build script as:

```
# chmod +x cockroachdb_debian9.8slim.sh
# ./cockroachdb_debian9.8slim.sh
```

Note: If you face any issue in accessing the contents of /v19.1.5 inside the container, please
try deleting the container and adding `--privileged=true` option to the run command.