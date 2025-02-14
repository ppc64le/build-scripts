To build docker image:docker build -t rethinkdb:v2.4.4 .

To run the docker image: docker run --name rethinkdb -v "$PWD:/data" -p 28015:28015 -p 29015:29015 -p 8080:8080 -d rethinkdb:v2.4.4
