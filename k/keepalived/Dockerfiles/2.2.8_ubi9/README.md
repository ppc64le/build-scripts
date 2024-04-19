Docker build command: docker build -t keepalived:v2.2.8 .

Docker run command: docker run --name keepalived1 --cap-add=NET_ADMIN --net=host -d keepalived:v2.2.8
