# Build CockroachDB v19.2.10-oss

Please find the instructions to build v19.2.10 release of CockroachDB and to execute the
community tests inside a UBI8 container below.



## UBI8 container

To run the container so that the build script and patches are available inside it, execute:

```
# docker container run -it -v `pwd`:/v19.2.10-oss --workdir /v19.2.10-oss --name ubi8_cockroach19.2.10-oss registry.access.redhat.com/ubi8/ubi:latest /bin/bash
```

If you face any issue in accessing the contents of /v19.2.10-oss inside the container, please
try deleting the container and adding `--privileged=true` option to the run command.

Enable execute permissions for the build script and run it as:

```
# chmod +x cockroachdb_ubi8.sh
# ./cockroachdb_ubi8.sh
```

