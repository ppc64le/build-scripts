# Build CockroachDB v22.1.8 docker image

Please find the instructions to build UBI 8 based docker image of
CockroachDB v22.1.8 below.

## UBI8 container

Copy the cockroach binary, licenses directory, libgeos from the build container, 
say ubi8_cockroach22.1.8-oss, to the current directory as:

```
# docker cp ubi8_cockroach22.1.8-oss:/root/go/src/github.com/cockroachdb/cockroach/cockroachoss .
# docker cp ubi8_cockroach22.1.8-oss:/root/go/src/github.com/cockroachdb/cockroach/licenses .
# docker cp ubi8_cockroach22.1.8-oss:/root/go/src/github.com/cockroachdb/cockroach/lib/libgeos.so .
# docker cp ubi8_cockroach22.1.8-oss:/root/go/src/github.com/cockroachdb/cockroach/lib/libgeos_c.so .
```

Now build the image by executing the following command:

```
# chmod +x cockroach.sh
# docker image build -f Dockerfile_ubi8 -t ibmcom/cockroach-ppc64le:v22.1.8-ubi8 .
```
