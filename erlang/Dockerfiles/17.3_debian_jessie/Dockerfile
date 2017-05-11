###Dockerfile for Erlang 
FROM ppc64le/openjdk:openjdk-8-jdk

#Install Erlang
RUN \
        apt-get update && \
        apt-get install -y erlang

#Start erlang shell
CMD ["erl"]
