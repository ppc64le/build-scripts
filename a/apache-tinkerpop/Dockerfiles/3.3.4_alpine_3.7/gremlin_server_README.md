Firstly, to run the following commands to build tinkerpop:
```bash
sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk maven git  

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

git clone https://github.com/apache/tinkerpop
cd tinkerpop
git checkout 3.3.4
mvn clean install
```

Next, build the gremlin-server docker image using the following  command:
cd gremlin-server
docker build --build-arg GREMLIN_SERVER_DIR=target/apache-tinkerpop-gremlin-server-3.3.4-standalone -t gremlin-server:3.3.4 .

To start the gremlin-server, use the following docker run command:
docker run -t gremlin_server:3.3.4

The following logs are observed:
```bash
[INFO] GremlinServer - 3.3.4
         \,,,/
         (o o)
-----oOOo-(3)-oOOo-----

[INFO] GremlinServer - Configuring Gremlin Server from conf/gremlin-server.yaml
[INFO] MetricManager - Configured Metrics ConsoleReporter configured with report interval=180000ms
[INFO] MetricManager - Configured Metrics CsvReporter configured with report interval=180000ms to fileName=/tmp/gremlin-server-metrics.csv
[INFO] MetricManager - Configured Metrics JmxReporter configured with domain= and agentId=
[INFO] MetricManager - Configured Metrics Slf4jReporter configured with interval=180000ms and loggerName=org.apache.tinkerpop.gremlin.server.Settings$Slf4jReporterMetrics
[INFO] DefaultGraphManager - Graph [graph] was successfully configured via [conf/tinkergraph-empty.properties].
[INFO] ServerGremlinExecutor - Initialized Gremlin thread pool.  Threads in pool named with pattern gremlin-*
[INFO] ServerGremlinExecutor - Initialized GremlinExecutor and preparing GremlinScriptEngines instances.
[INFO] ServerGremlinExecutor - Initialized gremlin-groovy GremlinScriptEngine and registered metrics
[INFO] ServerGremlinExecutor - A GraphTraversalSource is now bound to [g] with graphtraversalsource[tinkergraph[vertices:0 edges:0], standard]
[INFO] OpLoader - Adding the standard OpProcessor.
[INFO] OpLoader - Adding the session OpProcessor.
[INFO] OpLoader - Adding the traversal OpProcessor.
[INFO] TraversalOpProcessor - Initialized cache for TraversalOpProcessor with size 1000 and expiration time of 600000 ms
[INFO] GremlinServer - Executing start up LifeCycleHook
[INFO] Logger$info - Executed once at startup of Gremlin Server.
[INFO] GremlinServer - idleConnectionTimeout was set to 0 which resolves to 0 seconds when configuring this value - this feature will be disabled
[INFO] GremlinServer - keepAliveInterval was set to 0 which resolves to 0 seconds when configuring this value - this feature will be disabled
[INFO] AbstractChannelizer - Configured application/vnd.gremlin-v3.0+gryo with org.apache.tinkerpop.gremlin.driver.ser.GryoMessageSerializerV3d0
[INFO] AbstractChannelizer - Configured application/vnd.gremlin-v3.0+gryo-stringd with org.apache.tinkerpop.gremlin.driver.ser.GryoMessageSerializerV3d0
[INFO] AbstractChannelizer - Configured application/vnd.gremlin-v3.0+json with org.apache.tinkerpop.gremlin.driver.ser.GraphSONMessageSerializerV3d0
[INFO] AbstractChannelizer - Configured application/json with org.apache.tinkerpop.gremlin.driver.ser.GraphSONMessageSerializerV3d0
[INFO] GremlinServer$1 - Gremlin Server configured with worker thread pool of 1, gremlin pool of 16 and boss thread pool of 1.
[INFO] GremlinServer$1 - Channel started at port 8182.
```
