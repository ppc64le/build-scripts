Running LMDB container:

Build Dockerfile: 
$docker build -t ppc64le/lmdb .

Run Docker container:
Create directory /lmdb/data on your host.

#To access the container shell

$docker run -it -v /lmdb/data:/lmdb/data ppc64le/lmdb bash

or

#To run mdb_load commands

$docker run -t ppc64le/lmdb mdb_load <options>

