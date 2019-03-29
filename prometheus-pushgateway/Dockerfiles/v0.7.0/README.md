
To build the image run 
$ docker build -t prometheus-pushgateway:v0.7.0 .

To run the image run 
$ docker run -it -p 9091:9091 prometheus-pushgateway:v0.7.0 