# Using the Infinispan Docker image:

## Build the Infinispan docker image:
```bash
$ docker build -t infinispan-ubi .
```

## Run the Infinispan docker image:
```bash
$ docker run -it -d -p  11222:11222  -e USER=user -e  PASS=password infinispan-ubi
```

## Access the Infinispan site as:
```
http://<IP Address>:11222
```
