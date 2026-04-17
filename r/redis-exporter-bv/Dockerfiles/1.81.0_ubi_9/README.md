Redis Exporter Docker Setup Guide

This guide explains how to run Redis Exporter using Docker with a custom network and how to validate metrics output.

Step 0: Build the redis-exporter image

docker build -t redis-exporter:1.81.0 .

Step 1: Create a Docker network

Create a dedicated bridge network for communication between containers:

docker network create redis-exporter-network --driver bridge

Verify network creation:

docker network ls

Step 2: Run Redis Exporter container

Start the Redis Exporter container and attach it to the network:

docker run -d \
  --name redis-exporter-node1 \
  --network redis-exporter-network \
  REGISTRY_NAME/bitnami/redis-exporter:latest

Step 3: Verify container is running

Check running containers:

docker ps

Check logs:

docker logs redis-exporter-node1
What to look for:
Exporter started successfully
Listening on port 9121
No permission or missing binary errors

Step 4: Access metrics endpoint

Expose port while running container (if not already exposed externally):

docker run -d \
  --name redis-exporter-node1 \
  --network redis-exporter-network \
  -p 9121:9121 \
  REGISTRY_NAME/bitnami/redis-exporter:latest

Now access metrics:

curl http://localhost:9121/metrics
Expected output:

Prometheus-formatted metrics such as:

# HELP redis_up Redis instance is up
# TYPE redis_up gauge
redis_up 1

Step 5: Run multiple containers in same network

You can scale by adding more containers:

docker run -d \
  --name redis-exporter-node2 \
  --network redis-exporter-network \
  REGISTRY_NAME/bitnami/redis-exporter:latest

Step 6: Validate container networking

Check DNS resolution inside network:

docker exec -it redis-exporter-node1 ping redis-exporter-node2

Or check hostname resolution:

docker exec -it redis-exporter-node1 nslookup redis-exporter-node2

Step 7: Inspect logs in real time

Follow logs:

docker logs -f redis-exporter-node1

Check licenses and other files:
ls -R /opt/bitnami
ls -R /usr/sbin

Step 8: Full functional test

Run curl inside container network:

docker exec -it redis-exporter-node1 curl http://localhost:9121/metrics

Or from host:

curl http://localhost:9121/metrics

Step 9: Cleanup resources

Stop containers:

docker stop redis-exporter-node1 redis-exporter-node2

Remove containers:

docker rm redis-exporter-node1 redis-exporter-node2

Remove network:

docker network rm redis-exporter-network