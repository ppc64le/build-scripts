FROM alpine:3.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apk update && \
         apk add rethinkdb

VOLUME ["/data"]

WORKDIR /data

CMD ["rethinkdb", "--bind", "all"]

#   process cluster webui
EXPOSE 28015 29015 8080

