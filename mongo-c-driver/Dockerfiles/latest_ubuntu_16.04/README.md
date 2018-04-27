Docker build command:
docker build -t mongoc .

Docker run command:
docker run -t mongoc

Notes:
mongodb is already available inside the container. Depending on the requirement
it can be started using following command:
# mongo --host localhost --port 27017
Container is pre-configured to expose port 27017.
