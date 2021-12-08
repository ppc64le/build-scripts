# grpc-core

Building and saving `grpc-java (core)`

Step 1) Build the grpc-core builder image (once per release)

`$ docker build -t localhost/grpc-core-base:latest .`

Step 2) Compile and package binary

```$ docker run --rm --privileged -v `pwd`:/workspace localhost/grpc-core-base:latest bash -l -c "cd /workspace; ./grpc-core.sh"```

Build output is generated in `pwd` folder

Note: use `--privileged` only if mount fails with `Permission denied` error.
