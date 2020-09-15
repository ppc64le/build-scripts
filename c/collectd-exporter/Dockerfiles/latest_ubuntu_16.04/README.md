Collectd-Exporter

Building and running the container

$ docker build -t collectd-exporter .
$ docker run -d -p 9103:9103 -p 25826:25826/udp collectd-exporter --collectd.listen-address=":25826"

Now you will be able to access the collectd-exporter metrics from browser at:
http:/vm_ip:9103
