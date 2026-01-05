* To Build Fluentd Image: 
```bash
docker build -t fluentd:v1.17.0 .
```

To create and run the container from the image built: 

* Run the fluentd image:
```bash
docker run -p 24224:24224 -p 24224:24224/udp -u fluent -v /path/to/dir:/fluentd/log fluentd
```

*Note:* Make sure the *dir* you pass while creating container has write permissions

Reference:
- https://hub.docker.com/_/fluentd