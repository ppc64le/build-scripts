## Building Docker image:
Execute docker build command in the folder containing the Dockerfile:
```bash
cd build-scripts/k/kibana/Dockerfiles/8.1.0_ubi_8
docker build -t <your container repository>/kibana-ppc64le:8.1.0 .
docker push <your container repository>/kibana-ppc64le:8.1.0
```

## Deploying EFK stack on OCP 4.9:

Assuming images to be present at following locations:
- ibmcom/elasticsearch-ppc64le:8.1.0
- ibmcom/fluentd-elasticsearch-ppc64le:1.14.5
- ibmcom/kibana-ppc64le:8.1.0

### Create following resource files:

elasticsearch-deploy.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  labels:
    app: elasticsearch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      annotations:
        openshift.io/scc: anyuid
      name: elasticsearch
      labels:
        app: elasticsearch
    spec:
      containers:
      - env:
        - name: discovery.type
          value: single-node
        image: ibmcom/elasticsearch-ppc64le:8.1.0
        imagePullPolicy: IfNotPresent
        name: elasticsearch
        ports:
        - containerPort: 9300
          protocol: TCP
        - containerPort: 9200
          protocol: TCP
        resources: {}
        securityContext:
          capabilities:
            drop:
            - MKNOD
``` 
elasticsearch-svc.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  labels:
    app: elasticsearch
spec:
  selector:
    app: elasticsearch
  ports:
    - port: 9200
      name: rest
```
kibana-deploy.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  labels:
    app: kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      annotations:
        openshift.io/scc: anyuid
      name: kibana
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: ibmcom/kibana-ppc64le:8.1.0
        resources:
          limits:
            cpu: 1000m
          requests:
            cpu: 100m
        env:
          - name: ELASTICSEARCH_HOSTS
            value: '["http://elasticsearch:9200"]'
        ports:
        - containerPort: 5601
```
kibana-svc.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kibana
  labels:
    app: kibana
spec:
  selector:
    app: kibana
  ports:
    - port: 5601
      name: web
```
fluentd-cm.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd
  labels:
    app: fluentd
data:
  fluent.conf: |+
    <source>
      @type http
      port 9880
      bind 0.0.0.0
    </source>

    <match *.**>
      @type copy
      <store>
        @type elasticsearch
        host elasticsearch
        port 9200
        logstash_format true
        logstash_prefix fluentd-test
        logstash_dateformat %Y%m%d
        include_tag_key true
        type_name access_log
        tag_key @log_name
        flush_interval 1s
      </store>

      <store>
        @type stdout
      </store>
    </match>
```
fluentd-deploy.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fluentd
  labels:
    app: fluentd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      annotations:
        openshift.io/scc: anyuid
      name: fluentd
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: ibmcom/fluentd-elasticsearch-ppc64le:1.14.5
        resources:
          limits:
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 200Mi
        ports:
        - containerPort: 9880
        volumeMounts:
        - mountPath: /fluentd/etc/
          name: fluentd-config
      volumes:
      - configMap:
          defaultMode: 420
          name: fluentd
        name: fluentd-config
```
fluentd-svc.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: fluentd
  labels:
    app: fluentd
spec:
  selector:
    app: fluentd
  ports:
    - port: 9880
      name: rest
```

### Create a project on OCP:
```bash
oc new-project efkstack
```
### Create resources in following order:
```bash
oc create -f elasticsearch-deploy.yaml
oc create -f elasticsearch-svc.yaml
oc create -f kibana-deploy.yaml
oc create -f kibana-svc.yaml
oc create -f fluentd-cm.yaml
oc create -f fluentd-deploy.yaml
oc create -f fluentd-svc.yaml
```

### Check that all pods are up and running:
```bash
oc get all
NAME                                READY   STATUS    RESTARTS   AGE
pod/elasticsearch-dc85496d8-sjdss   1/1     Running   0          6m14s
pod/fluentd-798b9dbdd7-gdvxq        1/1     Running   0          108s
pod/kibana-b8d465949-7nfrc          1/1     Running   0          3m36s

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/elasticsearch   ClusterIP   172.30.2.83      <none>        9200/TCP   5m57s
service/fluentd         ClusterIP   172.30.235.132   <none>        9880/TCP   84s
service/kibana          ClusterIP   172.30.17.245    <none>        5601/TCP   3m23s

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/elasticsearch   1/1     1            1           6m14s
deployment.apps/fluentd         1/1     1            1           109s
deployment.apps/kibana          1/1     1            1           3m37s

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/elasticsearch-dc85496d8   1         1         1       6m14s
replicaset.apps/fluentd-798b9dbdd7        1         1         1       109s
replicaset.apps/kibana-b8d465949          1         1         1       3m36s
```

### Expose the fluentd and kibana services as these need to be accessed externally:
```bash
oc expose svc fluentd
oc expose svc kibana
```

### Check that routes are created:
```bash
oc get routes
NAME      HOST/PORT                                            PATH   SERVICES   PORT   TERMINATION   WILDCARD
fluentd   fluentd-efkstack.apps.xxx.yyy.zzz.com          fluentd    rest                 None
kibana    kibana-efkstack.apps.xxx.yyy.zzz.com           kibana     web                  None
```

### Call fluentd API to post some message:
```bash
curl -X POST -d 'json={"json":"A test message to test EFK stack"}' http://fluentd-efkstack.apps.xxx.yyy.zzz.com/sample.test
```

### Check in the logs that the message was received and processed by fluentd:
```bash
oc logs fluentd-798b9dbdd7-gdvxq | tail -5
2022-04-05 03:02:26 +0000 [info]: #0 starting fluentd worker pid=21 ppid=8 worker=0
2022-04-05 03:02:26 +0000 [info]: #0 fluentd worker is now running worker=0
2022-04-05 03:02:26.380559486 +0000 fluent.info: {"pid":21,"ppid":8,"worker":0,"message":"starting fluentd worker pid=21 ppid=8 worker=0"}
2022-04-05 03:02:26.388497546 +0000 fluent.info: {"worker":0,"message":"fluentd worker is now running worker=0"}
2022-04-05 03:20:20.260484356 +0000 sample.test: {"json":"A test message to test EFK stack"}
```

### Open Kibana dashboard using Kibana route to verify that fluentd sent the message to elasticsearch and can be access by Kibana:

#### Open Kibana Index Management console:
http://kibana-efkstack.apps.xxx.yyy.zzz.com/app/management/data/index_management/indices<br>
It should show the index created by Elasticsearch with the name:
fluentd-test-yyyymmdd

#### Open Kibana dataView console:
http://kibana-efkstack.apps.xxx.yyy.zzz.com/app/management/kibana/dataViews

#### Click on create data view.
Provide a name that matches the index created above. Example `fluentd*`

In the created data view, edit any Text type field and in the Preview navigate through all Document IDs which will show the messages posted by Fluentd to Elasticsearch.
