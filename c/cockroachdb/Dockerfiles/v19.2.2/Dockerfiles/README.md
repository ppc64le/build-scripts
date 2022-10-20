# Build CockroachDB v19.2.2 docker image

Please find the instructions to build UBI 7.6 based docker image of
CockroachDB v19.2.2 below.

## UBI 7.6 container

Copy the cockroach binary from the build container, say ubi7.6_cockroach19.2.2,
to the current directory as:

```
# docker cp ubi7.6_cockroach19.2.2:/root/go/src/github.com/cockroachdb/cockroach/cockroach .
```

Now build the image by executing the following command:

```
# chmod +x cockroach.sh
# docker image build -f Dockerfile_ubi7.6 -t ibmcom/cockroach-ppc64le:v19.2.2-ubi7 .
```