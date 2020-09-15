Docker build command:
docker built -t amqp .

Docker run command:
docker run -it amqp

Make necessary changes to AMQP server configuration and restart it using
command "service rabbitmq-server restart"

Example:
test@pts00433-vm23:~/amqp$ docker run -it amqp
 * Starting RabbitMQ Messaging Server rabbitmq-server                    [ OK ]

              RabbitMQ 3.5.7. Copyright (C) 2007-2015 Pivotal Software, Inc.
  ##  ##      Licensed under the MPL.  See http://www.rabbitmq.com/
  ##  ##
  ##########  Logs: /var/log/rabbitmq/rabbit@3cb406fbf1ee.log
  ######  ##        /var/log/rabbitmq/rabbit@3cb406fbf1ee-sasl.log
  ##########
              Starting broker... completed with 0 plugins.

