Running LMDB container:

Build Dockerfile: 
$docker build -t ppc64le/lmdb .

Run Docker container:
Create directory /lmdb/data on your host.
$docker run -itP -v /lmdb/data: /lmdb/data ppc64le/lmdb 

