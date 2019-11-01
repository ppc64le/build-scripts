# Redis an in-memory data structure store, used as a database, cache and message broker

## Building the container image

`$ docker build -t redis .`

## Starting the container

`$ docker run -d -p 6379:6379 --name redis-demo redis`

---

## Quick test using a new interactive session and the redis cli

`$ docker exec -it redis-demo sh`

```
sh-4.2# redis-cli

127.0.0.1:6379> ping
PONG
127.0.0.1:6379> get name
(nil)
127.0.0.1:6379> set name "foobar"
OK
127.0.0.1:6379> get name
"foobar"
```
