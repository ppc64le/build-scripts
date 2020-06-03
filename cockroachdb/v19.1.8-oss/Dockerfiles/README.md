# Build CockroachDB v19.1.8 docker image

Please find the instructions to build UBI7 based docker image of CockroachDB
v19.1.8 below.

## UBI7 container

Copy the cockroach binary from the build container, say ubi7_cockroach19.1.8-oss,
to the current directory as:

```
# docker cp ubi7_cockroach19.1.8-oss:/root/go/src/github.com/cockroachdb/cockroach/cockroachoss .
```

Now build the image by executing the following command:

```
# chmod +x cockroach.sh
# docker image build -f Dockerfile_ubi7 -t ibmcom/cockroach-ppc64le:v19.1.8-oss-ubi7 .
```
