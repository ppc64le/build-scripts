## Build Instructions

The Dockerfile is sourced from:
https://github.com/openresty/docker-openresty/blob/1.27.1.2-11/alpine/Dockerfile

The required nginx configuration files are downloaded during the Docker build directly from the OpenResty Docker repository.

### 1. Navigate to the version directory

```bash
cd 1.27.1.2-alpine
```

### 2. Build the Docker image

```bash
docker build -t openresty-ppc64le:1.27.1.2-alpine .
```