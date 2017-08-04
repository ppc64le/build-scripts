The docker image can be obtained using following command:
docker pull logstash-forwarder

A container can be created using following command:
How to create logstash-forwarder container
It is assumed that the cert file is located in following location:
./certs/logstash-forwarder.crt

docker run -t -v $PWD/certs:/opt/certs:ro -p5000:5000 logstash-forwarder
