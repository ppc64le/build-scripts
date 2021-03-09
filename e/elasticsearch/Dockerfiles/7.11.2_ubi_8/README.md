# ELK build steps

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

# Deployment on Openshift

```

$ oc new-project elasticsearch
--> Now using project "elasticsearch" on server "https://api.eldhanap-d36b.ibm.com:6443".
    You can add applications to this project with the 'new-app' command. For example, try:
    oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git
    to build a new example application in Ruby.

$ oc new-app docker.io/ibmcom/elasticsearch-ppc64le:v7.11.2
--> Found Docker image 9c48b43 (5 days old) from docker.io for "docker.io/ibmcom/elasticsearch-ppc64le:7.11.2"

    Red Hat Universal Base Image 8
    ------------------------------
    The Universal Base Image is designed and engineered to be the base layer for all of your containerized applications, middleware and utilities. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly.

    Tags: base rhel8

    * An image stream tag will be created as "elasticsearch-ppc64le:7.11.2" that will track this image
    * This image will be deployed in deployment config "elasticsearch-ppc64le"
    * Ports 9200/tcp, 9300/tcp will be load balanced by service "elasticsearch-ppc64le"
      * Other containers can access this service through the hostname "elasticsearch-ppc64le"
    * WARNING: Image "docker.io/ibmcom/elasticsearch-ppc64le:7.11.2" runs as the 'root' user which may not be permitted by your cluster administrator

--> Creating resources ...
    imagestream.image.openshift.io "elasticsearch-ppc64le" created
    deploymentconfig.apps.openshift.io "elasticsearch-ppc64le" created
    service "elasticsearch-ppc64le" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/elasticsearch-ppc64le'
    Run 'oc status' to view your app.

$ oc get all
NAME                                 READY     STATUS      RESTARTS   AGE
pod/elasticsearch-ppc64le-1-4cv5n    1/1       Running     0          4m2s
pod/elasticsearch-ppc64le-1-deploy   0/1       Completed   0          4m14s

NAME                                            DESIRED   CURRENT   READY     AGE
replicationcontroller/elasticsearch-ppc64le-1   1         1         1         4m14s

NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/elasticsearch-ppc64le   ClusterIP   172.30.195.199   <none>        9200/TCP,9300/TCP   4m16s

NAME                                                       REVISION   DESIRED   CURRENT   TRIGGERED BY
deploymentconfig.apps.openshift.io/elasticsearch-ppc64le   1          1         1         config,image(elasticsearch-ppc64le:7.11.2)

NAME                                                   IMAGE REPOSITORY                                                                       TAGS      UPDATED
imagestream.image.openshift.io/elasticsearch-ppc64le   image-registry.openshift-image-registry.svc:5000/elasticsearch/elasticsearch-ppc64le   7.11.2    4 minutes ago

$ oc expose svc/elasticsearch-ppc64le
route.route.openshift.io/elasticsearch-ppc64le exposed

$ oc get all
NAME                                 READY     STATUS      RESTARTS   AGE
pod/elasticsearch-ppc64le-1-4cv5n    1/1       Running     0          6m31s
pod/elasticsearch-ppc64le-1-deploy   0/1       Completed   0          6m43s

NAME                                            DESIRED   CURRENT   READY     AGE
replicationcontroller/elasticsearch-ppc64le-1   1         1         1         6m43s

NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/elasticsearch-ppc64le   ClusterIP   172.30.195.199   <none>        9200/TCP,9300/TCP   6m44s

NAME                                                       REVISION   DESIRED   CURRENT   TRIGGERED BY
deploymentconfig.apps.openshift.io/elasticsearch-ppc64le   1          1         1         config,image(elasticsearch-ppc64le:7.11.2)

NAME                                                   IMAGE REPOSITORY                                                                       TAGS      UPDATED
imagestream.image.openshift.io/elasticsearch-ppc64le   image-registry.openshift-image-registry.svc:5000/elasticsearch/elasticsearch-ppc64le   7.11.2    6 minutes ago

NAME                                             HOST/PORT                                                        PATH      SERVICES
               PORT       TERMINATION   WILDCARD
route.route.openshift.io/elasticsearch-ppc64le   elasticsearch-ppc64le-elasticsearch.apps.eldhanap-d36b.ibm.com             elasticsearch-ppc64le   9200-tcp                 None

$ curl -X GET elasticsearch-ppc64le-elasticsearch.apps.eldhanap-d36b.ibm.com/
{
  "name" : "elasticsearch-ppc64le-1-4cv5n",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "_na_",
  "version" : {
    "number" : "7.11.2-SNAPSHOT",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "unknown",
    "build_date" : "2021-03-09T15:16:31.630738807Z",
    "build_snapshot" : true,
    "lucene_version" : "8.7.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```


