Build Steps for Elasticsearch

```
docker build -t elasticsearch:7.17.1 .

docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.17.1
```

Validate the Image on Helm chart:

```
$ oc new-project elasticsearch
 
--> Now using project "elasticsearch" on server "https://api-<cluster-address>:6443".
    You can add applications to this project with the 'new-app' command. For example, try:
    oc new-app rails-postgresql-example
    to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:
    kubectl create deployment hello-node --image=k8s.gcr.io/e2e-test-images/agnhost:2.33 -- /agnhost serve-hostname

$ oc adm policy add-scc-to-user -z default -n elasticsearch privileged

--> clusterrole.rbac.authorization.k8s.io/system:openshift:scc:privileged added: "default"

$ helm repo add elastic https://helm.elastic.co

--> "elastic" has been added to your repositories

$ helm install elasticsearch elastic/elasticsearch -n elasticsearch -f elastic-values.yaml --version "7.17.1"

--> NAME: elasticsearch
    LAST DEPLOYED: Tue May 10 22:00:27 2022
    NAMESPACE: elasticsearch
    STATUS: deployed
    REVISION: 1
    NOTES:
    1. Watch all cluster members come up.
      $ kubectl get pods --namespace=elasticsearch -l app=hcl-commerce-elasticsearch -w2. Test cluster health using Helm test.
      $ helm --namespace=elasticsearch test elasticsearch
 
```

elastic-values.yaml

```
fullnameOverride: "hcl-commerce-elasticsearch"
image: "image-registry.openshift-image-registry.svc:5000/elasticsearch/elasticsearch"
imageTag: "7.17.1"
imagePullPolicy: "Always"
replicas: 1
minimumMasterNodes: 1
esJavaOpts: "-Xmx6g -Xms6g"
resources:
  requests:
    cpu: "1000m"
    memory: "6Gi"
  limits:
    cpu: "2000m"
    memory: "8Gi"
esConfig:
  elasticsearch.yml: |
    indices.query.bool.max_clause_count: 100000
    xpack.monitoring.collection.enabled: true
    xpack.ml.enabled: false
    bootstrap.system_call_filter: false
persistence:
  enabled: false
```

Check the Pod Status:

```
[root@sprucest1 elasticsearch]# oc get all
NAME                                 READY   STATUS    RESTARTS   AGE
pod/hcl-commerce-elasticsearch-0     1/1     Running   0          118m

NAME                                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
service/hcl-commerce-elasticsearch            ClusterIP   172.30.87.77    <none>        9200/TCP,9300/TCP   118m
service/hcl-commerce-elasticsearch-headless   ClusterIP   None            <none>        9200/TCP,9300/TCP   118m

NAME                                          READY   AGE
statefulset.apps/hcl-commerce-elasticsearch   1/1     118m
```
