## Build and Run Instructions

### Build the Docker Image

```bash
docker build -t redis-operator:ppc64le .
```

---

### Run the Redis Operator Container

```bash
docker run --rm redis-operator:ppc64le
```

This starts the Redis Operator using the default entrypoint:

```text
/operator manager
```

---

### Open an Interactive Shell Inside the Container

```bash
docker run -it --user root --entrypoint /bin/bash redis-operator:ppc64le
```

This launches an interactive shell for debugging or inspection.

---

## Notes

- The Dockerfile automatically:
  - Clones the Redis Operator source repository
  - Checks out version `v0.24.0`
  - Builds the operator binary
- No local source code checkout is required before building the image.
