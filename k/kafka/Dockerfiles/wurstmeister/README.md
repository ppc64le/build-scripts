# Kafka
This is docker based Kafka server. 

Following is the contents of `resource.yaml` file, that is used to test the Kafka & Zookeeper deployment on OCP cluster:
```
kind: List
apiVersion: v1
metadata: {}

items:

- apiVersion: v1
  kind: Template
  metadata:
    name: apache-kafka
    annotations:
      description: 1-pod Apache Kafka
      tags: messaging,streaming,kafka
  parameters:
  - name: NAME
    description: Name prefix for each object created
    required: true
    value: apache-kafka
  - name: KAFKA_IMAGE
    description: Image with Apache Kafka and Apache ZooKeeper
    required: true
    value: ibmcom/kafka-ppc64le:wurstmeister-2.6.0
  - name: ZOOKEEPER_IMAGE
    description: Image with Apache ZooKeeper
    value: ibmcom/zookeeper-ppc64le:3.6.2
  objects:
  - apiVersion: v1
    kind: DeploymentConfig
    metadata:
      name: ${NAME}
    spec:
      replicas: 1
      selector:
        deploymentconfig: ${NAME}
      template:
        metadata:
          labels:
            deploymentconfig: ${NAME}
        spec:
          hostname: ${NAME}
          containers:
          - name: apache-kafka
            image: ${KAFKA_IMAGE}
            command:
            - /usr/bin/start-kafka.sh
            env:
            - name: KAFKA_ADVERTISED_HOST_NAME
              value: ${NAME}
            - name: KAFKA_ZOOKEEPER_CONNECT
              value: "localhost:2181"
            - name: KAFKA_ADVERTISED_PORT
              value: "9092"
            - name: KAFKA_CREATE_TOPICS
              value: "test"
            ports:
            - containerPort: 9092
          - name: apache-zookeeper
            image: ${ZOOKEEPER_IMAGE}
            ports:
            - containerPort: 2181
          - name: kafka-producer
            image: ${KAFKA_IMAGE}
            command:
            - bash
            env:
            - name: HOST_IP
              value: "localhost"
            - name: ZK
              value: "localhost:2181"
  - apiVersion: v1
    kind: Service
    metadata:
      name: ${NAME}
    spec:
      ports:
      - name: kafka
        port: 9092
      - name: zookeeper
        port: 2181
      selector:
        deploymentconfig: ${NAME}
```
Run `oc create -f resources.yaml && oc new-app apache-kafka` to deploy the Kafka on OCP cluster.

## Steps to follow to deploy Kafka along with Zookeeper on Kuberenetes Cluster in details:
1. Kafka depends on Zookeeper. First deploy the Zookeeper
```
kind: Deployment
apiVersion: apps/v1
metadata:
  name: zookeeper-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: zookeeper-1
  template:
    metadata:
      labels:
        app: zookeeper-1
    spec:
      containers:
      - name: zoo1
        image: ibmcom/zookeeper_ubi7:3.6.2
        ports:
        - containerPort: 2181
```
2. Exposing Zookeeper service.
```
apiVersion: v1
kind: Service
metadata:
  name: zoo1
  labels:
    app: zookeeper-1
spec:
  ports:
  - name: client
    port: 2181
    protocol: TCP
  - name: follower
    port: 2888
    protocol: TCP
  - name: leader
    port: 3888
    protocol: TCP
  selector:
    app: zookeeper-1
```


3. Deploying Kafka
```
apiVersion: v1
kind: Service
metadata:
  name: kafka-service
  labels:
    name: kafka
spec:
  ports:
  - port: 9092
    name: kafka-port
    protocol: TCP
  selector:
    app: kafka
    id: "0"
  type: LoadBalancer
```

4. Deploying Kafka Broker
```
kind: Deployment
apiVersion: apps/v1
metadata:
  name: kafka-broker0
spec:
  replicas: 2
  selector:
    matchLabels:
        app: kafka
        id: "0"
  template:
    metadata:
      labels:
        app: kafka
        id: "0"
    spec:
      containers:
      - name: kafka
        image: ibmcom/kafka-ppc64le:wurstmeister-2.6.0
        ports:
        - containerPort: 9092
        env:
        - name: KAFKA_ADVERTISED_PORT
          value: "30718"
        - name: KAFKA_ADVERTISED_HOST_NAME
          value: localhost
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: zoo1:2181
        - name: KAFKA_BROKER_ID
          value: "0"
        - name: KAFKA_CREATE_TOPICS
          value: Topic1
```

5. Save the above into a file and name it as kafka_deploy.yaml.
6. Run ```kubectl.exe create -f kafka_deploy.yaml``` to deploy the Kafka and Zookeeper.

### Note:
This Kafka docker is adopted from https://github.com/wurstmeister/kafka-docker
Please refer the https://github.com/wurstmeister/kafka-docker/blob/master/README.md for more details.