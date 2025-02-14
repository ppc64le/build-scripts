# Building Zookeeper
```
docker build -t zookeeper .
docker run --name zookeeper -it -p 2181:2181 -p 2888:2888 -p 3888:3888 zookeeper:latest