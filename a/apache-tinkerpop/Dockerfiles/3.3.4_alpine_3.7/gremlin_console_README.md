Run the following commands to install tinkerpop:
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

Next, build the gremlin-console docker image using the following  command:
cd gremlin-console
docker build --build-arg GREMLIN_CONSOLE_DIR=target/apache-tinkerpop-gremlin-console-3.3.4-standalone -t gremlin-console:3.3.4 .

Run the image using the following command:
docker run -it gremlin_console:3.3.4 

To test the working of Container (try below example)
```bash

         \,,,/
         (o o)
-----oOOo-(3)-oOOo-----
plugin activated: tinkerpop.server
plugin activated: tinkerpop.utilities
plugin activated: tinkerpop.tinkergraph
gremlin> graph = TinkerFactory.createModern()
==>tinkergraph[vertices:6 edges:6]
gremlin> g = graph.traversal()
==>graphtraversalsource[tinkergraph[vertices:6 edges:6], standard]
gremlin> g.V() 
==>v[1]
==>v[2]
==>v[3]
==>v[4]
==>v[5]
==>v[6]
gremlin> g.V(1) 
==>v[1]
gremlin> g.V(1).values('name')
==>marko
gremlin> g.V(1).outE('knows') 
==>e[7][1-knows->2]
==>e[8][1-knows->4]
gremlin> g.V(1).outE('knows').inV().values('name') 
==>vadas
==>josh
gremlin> g.V(1).out('knows').values('name')
==>vadas
==>josh
gremlin> g.V(1).out('knows').has('age', gt(30)).values('name') 
==>josh
```

