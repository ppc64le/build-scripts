1) Build and run kafka docker image 
```
  docker build -t kafka .
  docker run -it kafka /bin/bash
```

2)  Now launch the two single node servers
```
cd /root/kafka
bin/zookeeper-server-start.sh -daemon config/zookeeper.properties &
bin/kafka-server-start.sh -daemon config/server.properties &
```
Note: Both servers should start in the background, check the logs in /root/kafka/logs/ for more information.


3) Now create and list a simple test topic and messages file
```
bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test &
bin/kafka-topics.sh --list --zookeeper localhost:2181
```

4) Create a quick messages file (you can also enter it on the console) then produce those messages onto the test topic created earlier
```
echo -e "Congratulations\nThe build is working\n\nWelcome to Apache Kafka with Linux on ppc64le Systems" > /tmp/msg.log
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test < /tmp/msg.log
```

5) Run the consumer and check the results
And finally run a consumer to pull these messages back off the node
```
bin/kafka-console-consumer.sh --bootstrap-server  localhost:9092  --topic test --from-beginning --max-messages 4
```
You should see the following:
```
Congratulations
The build is working
  		
Welcome to Apache Kafka with Linux on ppc64le Systems
Consumed 4 messages
```

Note: If the producer is run to accept input from the console (without the < /tmp/msg.log part) and the consumer is run without --max-messages 4 from two different terminals you can see response as you enter each line.
So far we have been running against a single broker, for setting up a multi-broker cluster please refer link - http://kafka.apache.org/documentation.html#quickstart
