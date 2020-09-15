The docker image can be obtained using following command:
docker pull logstash-forwarder

Assumptions:
- It is assumed that necessary TLS/SSL infrastructure is already in place.
- It is assumed that the cert file is located in following location:
  ./certs/logstash-forwarder.crt
- It is assumed that logstash is already setup (say in another container
  or VM or server). This server is to be specified in the configuration
  file of logstash-forwarder as "server" value.

A container can be created using following command:
docker run -t -v $PWD/certs:/opt/certs:ro -p 5000:5000 logstash-forwarder
