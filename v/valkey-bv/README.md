# Valkey Bitnami Docker Image

This repository contains a Dockerfile for building a **Valkey 9.0.1** Bitnami container image based on Red Hat UBI 9 minimal.

---

## Build the Image

Use the following command to build the Docker image:
```bash
docker build -t <image_name:tag> .
```
Run the Container using the image:
```bash
docker run --name <container_name> -e ALLOW_EMPTY_PASSWORD=yes <image_name:tag>

Example:
docker run --name valkey-server -e ALLOW_EMPTY_PASSWORD=yes valkey:9.0.1
```
## Basic Validation
Once the container is running, you can check logs, connect to the shell, and test the Valkey server.

Check logs:
```bash
docker logs <container_name>
```
Open an interactive shell inside the container:
```bash
docker exec -it <container_name> /bin/sh

You should see a shell prompt like:
sh-5.1$
```
Verify Valkey processes:
```
ps aux | grep valkey
```
Test the Valkey CLI:
```bash
valkey-cli
```
Example session inside `valkey-cli`:
```bash
127.0.0.1:6379> set foo bar
OK
127.0.0.1:6379> get foo
"bar"
127.0.0.1:6379> incr mycounter
(integer) 1
127.0.0.1:6379> ping
PONG
127.0.0.1:6379> info server
```
