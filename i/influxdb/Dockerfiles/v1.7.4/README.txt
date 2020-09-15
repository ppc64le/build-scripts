InfluxDB is an open source time series database for recording metrics, events, and analytics

Supported Tags: 1.7.4

Start the container docker run -p 8086:8086 -d -v influxdb:/var/lib/influxdb -t ppc64le/influxdb:1.7.4

Using the HTTP APIs Creating a DB named mydb: $ curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE mydb"

Writing data using the HTTP API curl -i -XPOST 'http://localhost:8086/write?db=mydb' --data-binary 'cpu_load_short,host=server01,region=us-west value=0.64 1434055562000000000'

HTTP response summary .2xx: If your write request received HTTP 204 No Content, it was a success! .4xx: InfluxDB could not understand the request. .5xx: The system is overloaded or significantly impaired.

For more details refer to: https://docs.influxdata.com/influxdb/v1.3/guides/writing_data/