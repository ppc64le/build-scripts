How to use this image

1)RabbitMQ Broker
I)start a celery worker (RabbitMQ Broker)
	$ docker run --link some-rabbit:rabbit --name some-celery -d celery
II)check the status of the cluster
	$ docker run --link some-rabbit:rabbit --rm celery celery status

2)Redis Broker
To start a celery worker (Redis Broker)
I)) Start a redis container 
	$ docker run --link some-redis:redis -e CELERY_BROKER_URL=redis://redis --name some-celery -d celery
II)check the status of the cluster
	$ docker run --link some-redis:redis -e CELERY_BROKER_URL=redis://redis --rm celery celery status

