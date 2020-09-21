#docker build command


docker build -t redisgraph .

#docker run command


docker run -p 6379:6379 -it --rm redisgraph

#give it a try


Install redis-cli and run it 
$redis-cli

127.0.0.1:6379> ping

PONG

