
How to run Mongo-go-driver Package
-------------

To run these basic driver tests of Mongo-go-driver, make sure a standalone MongoDB server instance is running. Follow below steps to test the script.

Step 1 - 

    docker pull registry.access.redhat.com/ubi8:8.5

*************************

Step 2 -

    docker pull <MongoDB(version 4.0.24) ppc64le Image>

*************************

Step 3 -

    docker run -d -p 27017:27017  <MongoDB(version 4.0.24) ppc64le Image> mongod --setParameter enableTestCommands=1 --dbpath=/tmp --bind_ip_all

*************************

Step 4 -

    docker run --network host -v /var/run/docker.sock:/var/run/docker.sock -it registry.access.redhat.com/ubi8/ubi:8.5
    
*************************

Step 5 -

    Last step will give a prompt inside UBI8.5 container, run build script in it.

*************************
