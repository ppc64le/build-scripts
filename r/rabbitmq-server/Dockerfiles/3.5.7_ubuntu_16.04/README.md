Docker build command:
docker build -t ppc64le/rabbitmq-server:3.5.7

Docker pull command:
docker pull ppc64le/rabbitmq-server:3.5.7

Sample Docker run command
docker run -d -p 5672:5672 -p 15672:15672 -p 25672:25672 rabbitmq-server:latest "rabbitmq-server"

To test the image, run the following command on the host
curl http://localhost:5672

