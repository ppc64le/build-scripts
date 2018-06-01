Docker build command:
docker build -t elk_stack .

Docker run command:
docker run -d -p 80:80 -p 9200:9200 -p 9300:9300 elk_stack:latest_stable "/usr/bin/supervisord"
