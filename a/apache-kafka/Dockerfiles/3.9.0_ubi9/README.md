#To build a Dockerfile
docker build -t kafka-ubi9:ppc64le .

#To validate the dockerfile
docker run -d -p 9092:9092 --name kafka-container kafka-ubi9:ppc64le