Building Elasticsearch

Docker build command: docker build -t elasticsearch:7.17.2 .
Docker run command: docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.17.2

Deploying Elasticsearch on Opeshift

```
$ oc new-project elasticsearch
Now using project "elasticsearch" on server "https:api-<cluster-address>:6443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app rails-postgresql-example

to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=k8s.gcr.io/e2e-test-images/agnhost:2.33 -- /agnhost serve-hostname

$ oc new-app image-registry.openshift-image-registry.svc:5000/elasticsearch3/elasticsearch:7.17.2
warning: Cannot check if git requires authentication.
--> Found container image 3c8136d (27 hours old) from image-registry.openshift-image-registry.svc:5000 for "image-registry.openshift-image-registry.svc:5000/elasticsearch3/elasticsearch:7.17.2"

    Red Hat Universal Base Image 8
    ------------------------------
    The Universal Base Image is designed and engineered to be the base layer for all of your containerized applications, middleware and utilities. This base image is freely redistributable, but Red Hat only supports Red Hat technologies through subscriptions for Red Hat products. This image is maintained by Red Hat and updated regularly.

    Tags: base rhel8

    * An image stream tag will be created as "elasticsearch:7.17.2" that will track this image

--> Creating resources ...
    deployment.apps "elasticsearch" created
    service "elasticsearch" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose service/elasticsearch'
    Run 'oc status' to view your app.
$ oc get all
NAME                                READY   STATUS    RESTARTS   AGE
pod/elasticsearch-7dcc6654c-fc5jg   1/1     Running   0          11s

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/elasticsearch   ClusterIP   172.30.248.181   <none>        9200/TCP,9300/TCP   12s

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/elasticsearch   1/1     1            1           12s

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/elasticsearch-599879f65b   0         0         0       11s
replicaset.apps/elasticsearch-7dcc6654c    1         1         1       11s

NAME                                           IMAGE REPOSITORY                                                                                           TAGS     UPDATED
imagestream.image.openshift.io/elasticsearch   default-route-openshift-image-registry.apps.<cluster-address>/elasticsearch3/elasticsearch   7.17.2   About a minute ago
$ oc expose service/elasticsearch
route.route.openshift.io/elasticsearch exposed
$ oc status
In project elasticsearch3 on server https://api-<cluster-address>:6443

http://elasticsearch-elasticsearch3.apps.<cluster-address> to pod port 9200-tcp (svc/elasticsearch)
  deployment/elasticsearch deploys istag/elasticsearch:7.17.2
    deployment #2 running for 38 seconds - 1 pod (warning: 1 restarts)
    deployment #1 deployed 38 seconds ago


1 warning, 1 info identified, use 'oc status --suggest' to see details.
$ oc get all
NAME                                READY   STATUS    RESTARTS      AGE
pod/elasticsearch-7dcc6654c-fc5jg   1/1     Running   1 (29s ago)   47s

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/elasticsearch   ClusterIP   172.30.248.181   <none>        9200/TCP,9300/TCP   48s

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/elasticsearch   1/1     1            1           48s

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/elasticsearch-599879f65b   0         0         0       47s
replicaset.apps/elasticsearch-7dcc6654c    1         1         1       47s

NAME                                           IMAGE REPOSITORY                                                                                           TAGS     UPDATED
imagestream.image.openshift.io/elasticsearch   default-route-openshift-image-registry.apps.<cluster-address>/elasticsearch3/elasticsearch   7.17.2   About a minute ago

NAME                                     HOST/PORT                                                           PATH   SERVICES        PORT       TERMINATION   WILDCARD
route.route.openshift.io/elasticsearch   elasticsearch-elasticsearch3.apps.<cluster-address>          elasticsearch   9200-tcp                 None
```

