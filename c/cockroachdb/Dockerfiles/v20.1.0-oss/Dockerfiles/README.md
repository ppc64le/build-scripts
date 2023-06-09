# Build CockroachDB v20.1.0 docker image

Please find the instructions to build UBI 8 based docker image of
CockroachDB v20.1.0 below.

## UBI8 container

Copy the cockroach binary from the build container, say ubi8_cockroach20.1.0-oss,
to the current directory as:

```
# docker cp ubi8_cockroach20.1.0-oss:/root/go/src/github.com/cockroachdb/cockroach/cockroachoss .
```

Now build the image by executing the following command:

```
# chmod +x cockroach.sh
# docker image build -f Dockerfile_ubi8 -t ibmcom/cockroach-ppc64le:v20.1.0-ubi8 .
```
