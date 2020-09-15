#ELK build steps

```
sudo docker build -t elasticsearch .
sudo docker build -t kibana .
sudo docker build -t logstash .

sudo  docker network create elk
sudo docker run -it --name elasticsearch --net elk -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:latest
sudo docker run -it --name kibana -p 5601:5601  --net elk kibana:latest
sudo docker run -it --name logstash -p 9600:9600 -p 5044:5044 --net elk logstash:latest
```

Then access kibana through browser <ip>:5601

