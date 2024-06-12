# Build CockroachDB v19.2.10 docker image

Please find the instructions to build UBI 8 based docker image of
CockroachDB v19.2.10 below.

## UBI8 container

Copy the cockroach binary from the build container, say ubi8_cockroach19.2.10-oss,
to the current directory as:

```
# docker cp ubi8_cockroach19.2.10-oss:/root/go/src/github.com/cockroachdb/cockroach/cockroachoss .
```

Now build the image by executing the following command:

```
# chmod +x cockroach.sh
# docker image build -f Dockerfile_ubi8 -t ibmcom/cockroach-ppc64le:v19.2.10-ubi8 .
```
