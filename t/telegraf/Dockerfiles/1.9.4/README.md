# Telegraf

Telegraf is an open source agent written in Go for collecting metrics and data
on the system it's running on or from other services. Telegraf writes data it
collects to InfluxDB in the correct format.

Telegraf official Docs -
https://docs.influxdata.com/telegraf/v1.5/introduction/getting_started/

# Create telegraf image 
$ docker build -t influxdb-ppc64le:1.9.4 .

# Using this image

Exposed Ports:
8125 StatsD
8092 UDP
8094 TCP

Using the default configuration :
The default configuration requires a running InfluxDB instance as an output
plugin. Ensure that InfluxDB is running on port 8086 before starting the
Telegraf container.

Minimal example to start an InfluxDB container:

$ docker run -d --name influxdb -p 8083:8083 -p 8086:8086 ibmcom/influxdb-ppc64le:0.10
Starting Telegraf using the default config, which connects to InfluxDB at
http://localhost:8086/:

Manually create the InfluxDB database with:
$ curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE telegraf"

Why we need to create the DB manually?
In version 0.10 InfluxDB used a GET request to create the database[1], in 0.13
the method was changed to be a POST[2]. Telegraf 1.5 only support creating the
database via a POST, and so it will return database not found: "telegraf". If
you want to avoid crating DB manually, then you need to use InfluxDB:0.13 or
higher version image which is currently not available for ppc64le)

$ docker run --net=container:influxdb telegraf-ppc64le:1.9.4

For more usage please visit - https://hub.docker.com/r/library/telegraf/
