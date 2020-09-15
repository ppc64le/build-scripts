How to use this image

To create endpoint that collects logs on your host just run:

docker run -d -p 24224:24224 -p 24224:24224/udp -v /data:/fluentd/log fluentd

Default configurations are:

listen port 24224 for Fluentd forward protocol

store logs with tag docker.** into /fluentd/log/docker.*.log (and symlink docker.log)

store all other logs into /fluentd/log/data.*.log (and symlink data.log)

Note - Make sure that folders given in -v options are present on your host and has correct permissions. 
