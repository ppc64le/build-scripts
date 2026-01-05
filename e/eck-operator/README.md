For Validation:

1. Download following files:

wget https://download.elastic.co/downloads/eck/2.9.0/crds.yaml

wget  https://download.elastic.co/downloads/eck/2.9.0/operator.yaml

- Edit operator.yaml file to point to correct operator image:

Example:

vi operator.yaml

-------------

      containers:

        - image: "image-registry.openshift-image-registry.svc:5000/elastic-system/eck-operator-root:2.5.0-v1.10.0-dirty"

          imagePullPolicy: IfNotPresent

-------------

2. On OCP cluster for ECK operator:

# oc new project elastic-system
# HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
# docker tag eck-operator:latest $HOST/elastic-system/eck-operator:2.9.0
# docker push $HOST/elastic-system/eck-operator:2.9.0

3.Elasticsearch image can be built from source (using Dockerfile available in build script repository) or can be pulled from icr.io (icr.io/ppc64le-oss/elasticsearch-ppc64le:7.17.14)

# docker tag elasticsearch-ppc64le:8.3.2 $HOST/elastic-system/elasticsearch-ppc64le:7.17.14
# docker push $HOST/elastic-system/elasticsearch-ppc64le:7.17.14

# oc create -f crds.yaml -n elastic-system
# oc apply -f operator.yaml -n elastic-system

OUTPUT:
# oc get all
Warning: apps.openshift.io/v1 DeploymentConfig is deprecated in v4.14+, unavailable in v4.10000+
NAME                     READY   STATUS    RESTARTS   AGE
pod/elastic-operator-0   1/1     Running   0          12s

NAME                             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/elastic-webhook-server   ClusterIP   172.30.26.13   <none>        443/TCP   13s

NAME                                READY   AGE
statefulset.apps/elastic-operator   1/1     12s

NAME                                                   IMAGE REPOSITORY                                                                                             TAGS    UPDATED
imagestream.image.openshift.io/eck-operator            default-route-openshift-image-registry.apps.test-ocp-isv-00b5.ibm.com/elastic-system/eck-operator            2.9.0   6 minutes ago


#cat <<EOF | kubectl apply -n elastic-system -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.12.0
  image: image-registry.openshift-image-registry.svc:5000/elastic-system/elasticsearch-ppc64le:7.17.14
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
      xpack.ml.enabled: false
    podTemplate:
      spec:
        volumes:
        - name: elasticsearch-data
          emptyDir: {}
EOF


OUTPUT:
# oc get all
Warning: apps.openshift.io/v1 DeploymentConfig is deprecated in v4.14+, unavailable in v4.10000+
NAME                          READY   STATUS    RESTARTS   AGE
pod/elastic-operator-0        1/1     Running   0          3m15s
pod/quickstart-es-default-0   1/1     Running   0          64s

NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/elastic-webhook-server        ClusterIP   172.30.26.13     <none>        443/TCP    3m16s
service/quickstart-es-default         ClusterIP   None             <none>        9200/TCP   64s
service/quickstart-es-http            ClusterIP   172.30.96.59     <none>        9200/TCP   66s
service/quickstart-es-internal-http   ClusterIP   172.30.158.108   <none>        9200/TCP   66s
service/quickstart-es-transport       ClusterIP   None             <none>        9300/TCP   66s

NAME                                     READY   AGE
statefulset.apps/elastic-operator        1/1     3m15s
statefulset.apps/quickstart-es-default   1/1     64s

NAME                                                   IMAGE REPOSITORY                                                                                             TAGS    UPDATED
imagestream.image.openshift.io/eck-operator            default-route-openshift-image-registry.apps.test-ocp-isv-00b5.ibm.com/elastic-system/eck-operator            2.9.0   9 minutes ago
imagestream.image.openshift.io/elasticsearch-ppc64le   default-route-openshift-image-registry.apps.test-ocp-isv-00b5.ibm.com/elastic-system/elasticsearch-ppc64le   7.17.14   7 minutes ago


# oc create route passthrough elastic -n elastic-system --service=quickstart-es-default
# (oc get secret -n elastic-system quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
# PASSWORD=T83Hpt71Io5kQPM436e8hEm7


# curl -k -u "elastic:$PASSWORD" -X PUT "https://elastic-elastic-system.apps.test-ocp-isv-00b5.ibm.com/_cluster/settings?pretty" -H 'Content-Type: application/json' -d'

{

  "persistent": {

    "action.auto_create_index": "my-index-000001,index10,-index1*,+ind*"

  }

}

OUTPUT:
{
  "acknowledged" : true,
  "persistent" : {
    "action" : {
      "auto_create_index" : "my-index-000001,index10,-index1*,+ind*"
    }
  },
  "transient" : { }
}

# curl -k -u "elastic:$PASSWORD" -X POST "https://elastic-elastic-system.apps.test-ocp-isv-00b5.ibm.com/my-index-000001/_doc/?pretty" -H 'Content-Type: application/json' -d'

{

  "@timestamp": "2099-11-15T13:12:00",

  "message": "GET /search HTTP/1.1 200 1070000",

  "user": {

    "id": "kimchy"

  }

}

OUTPUT
{
  "_index" : "my-index-000001",
  "_id" : "YSSfSZABRI0Jzofz6SlG",
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 2,
    "successful" : 1,
    "failed" : 0
  },
  "_seq_no" : 0,
  "_primary_term" : 1
}


# curl -k -u "elastic:$PASSWORD" -X GET "https://elastic-elastic-system.apps.test-ocp-isv-00b5.ibm.com/my-index-000001/_doc/0?pretty"
{
  "_index" : "my-index-000001",
  "_id" : "0",
  "found" : false
}
