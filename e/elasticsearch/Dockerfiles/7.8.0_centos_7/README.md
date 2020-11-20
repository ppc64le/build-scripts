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
$ oc new-app docker.io/ibmcom/elasticsearch-ppc64le:v7.8.0
--> Found container image 1f493a9 (7 months old) from docker.io for "docker.io/ibmcom/elasticsearch-ppc64le:v7.8.0"

    * An image stream tag will be created as "elasticsearch-ppc64le:v7.8.0" that will track this image

--> Creating resources ...
    imagestream.image.openshift.io "elasticsearch-ppc64le" created
    deployment.apps "elasticsearch-ppc64le" created
    service "elasticsearch-ppc64le" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/elasticsearch-ppc64le'
    Run 'oc status' to view your app.

$ oc get all
NAME                                        READY   STATUS    RESTARTS   AGE
pod/elasticsearch-ppc64le-f7f496c77-g5cwg   1/1     Running   0          95s

NAME                            TYPE           CLUSTER-IP       EXTERNAL-IP                            PORT(S)             AGE
service/elasticsearch-ppc64le   ClusterIP      172.30.163.211   <none>                                 9200/TCP,9300/TCP   96s
service/kubernetes              ClusterIP      172.30.0.1       <none>                                 443/TCP             22d
service/openshift               ExternalName   <none>           kubernetes.default.svc.cluster.local   <none>              22d

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/elasticsearch-ppc64le   1/1     1            1           96s

NAME                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/elasticsearch-ppc64le-c5d85cc7    0         0         0       96s
replicaset.apps/elasticsearch-ppc64le-f7f496c77   1         1         1       95s

NAME                                                   IMAGE REPOSITORY                                                                                  TAGS     UPDATED
imagestream.image.openshift.io/elasticsearch-ppc64le   default-route-openshift-image-registry.apps.shivani3-fe3c.ocp.com/default/elasticsearch-ppc64le   v7.6.0   About a minute ago

$ oc expose svc/elasticsearch-ppc64le
route.route.openshift.io/elasticsearch-ppc64le exposed

$ oc get all
NAME                                        READY   STATUS    RESTARTS   AGE
pod/elasticsearch-ppc64le-f7f496c77-g5cwg   1/1     Running   0          5m48s

NAME                            TYPE           CLUSTER-IP       EXTERNAL-IP                            PORT(S)             AGE
service/elasticsearch-ppc64le   ClusterIP      172.30.163.211   <none>                                 9200/TCP,9300/TCP   5m49s
service/kubernetes              ClusterIP      172.30.0.1       <none>                                 443/TCP             22d
service/openshift               ExternalName   <none>           kubernetes.default.svc.cluster.local   <none>              22d

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/elasticsearch-ppc64le   1/1     1            1           5m49s

NAME                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/elasticsearch-ppc64le-c5d85cc7    0         0         0       5m49s
replicaset.apps/elasticsearch-ppc64le-f7f496c77   1         1         1       5m48s

NAME                                                   IMAGE REPOSITORY                                                                                  TAGS     UPDATED
imagestream.image.openshift.io/elasticsearch-ppc64le   default-route-openshift-image-registry.apps.shivani3-fe3c.ocp.com/default/elasticsearch-ppc64le   v7.8.0   5 minutes ago

NAME                                             HOST/PORT                                                  PATH   SERVICES                PORT       TERMINATION   WILDCARD
route.route.openshift.io/elasticsearch-ppc64le   elasticsearch-ppc64le-default.apps.shivani3-fe3c.ocp.com          elasticsearch-ppc64le   9200-tcp                 None

$ curl -X GET elasticsearch-ppc64le-default.apps.shivani3-fe3c.ocp.com/
{
  "name" : "elasticsearch-ppc64le-f7f496c77-g5cwg",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "_na_",
  "version" : {
    "number" : "7.68.0-SNAPSHOT",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "7f634e9f44834fbc12724506cc1da681b0c3b1e3",
    "build_date" : "2020-04-07T09:25:27.698930Z",
    "build_snapshot" : true,
    "lucene_version" : "8.4.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for
```


