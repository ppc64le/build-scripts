# ZooKeeper 3.9.5 ppc64le — OpenShift Validation

## Overview

This document describes the validation of the **Apache ZooKeeper 3.9.5 ppc64le** image on OpenShift.

Validation covered:

- Pushing the ppc64le image to the OpenShift internal registry using Podman
- Deploying ZooKeeper with the Bitnami Helm chart
- Verifying the custom ppc64le image is used by the running pod
- Verifying the ZooKeeper runtime version
- Performing a ZooKeeper health check
- Validating client connectivity
- Validating ZNode create, read, and delete operations

---

## 1. Environment

| Component | Details |
|---|---|
| Platform | OpenShift SNO |
| Architecture | ppc64le |
| ZooKeeper | 3.9.5 |
| Namespace | `zoo-keeper` |
| Helm Chart | Bitnami ZooKeeper `13.8.7` |
| Image | `zookeeper:3.9.5-ppc64le` |
| Container Tool | Podman |

---

## 2. OpenShift Project and Registry

### Verify project

```bash
oc project
```

Expected:

```text
Using project "zoo-keeper"
```

### Enable registry route

```bash
oc patch configs.imageregistry.operator.openshift.io cluster   --type=merge   -p '{"spec":{"defaultRoute":true}}'
```

Verify:

```bash
oc get route -n openshift-image-registry
```

### Set registry host

```bash
export HOST=$(oc get route default-route   -n openshift-image-registry   --template='{{ .spec.host }}')

echo $HOST
```

---

## 3. Push Image Using Podman

### Create and Verify local image


```bash
podman build --platform linux/ppc64le -t zookeeper:3.9.5-ppc64le .

podman images | grep zookeeper
```

Expected:

```text
localhost/zookeeper   3.9.5-ppc64le
```

### Tag image for OCP registry

```bash
docker tag zookeeper:3.9.5-ppc64le $HOST/zoo-keeper/zookeeper:3.9.5-ppc64le
```

Verify:

```bash
podman images | grep zookeeper
```

### Authenticate

```bash
oc whoami
oc whoami -t
```

Login:

```bash
podman login --tls-verify=false   -u "$(oc whoami)"   -p "$(oc whoami -t)"   $HOST
```

### Push

```bash
podman push --tls-verify=false   $HOST/zoo-keeper/zookeeper:3.9.5-ppc64le
```

Successful output includes:

```text
Getting image source signatures
Copying blob ... done
Copying config ... done
Writing manifest to image destination
```

### Verify ImageStream

```bash
oc get imagestream -n zoo-keeper
```

Expected tag:

```text
zookeeper   .../zoo-keeper/zookeeper   3.9.5-ppc64le
```

---

# 4. Helm Deployment

## Check ZooKeeper chart

```bash
helm search repo bitnami/zookeeper --versions | head -20
```

Chart used:

```text
Chart Version: 13.8.7
App Version:   3.9.3
```

The chart's default image is 3.9.3, but it is overridden with the custom **3.9.5-ppc64le** image.

## Export default values

```bash
helm show values bitnami/zookeeper   --version 13.8.7 > zookeeper-default-values.yaml
```

## Create `values.yaml`

```yaml
global:
  security:
    allowInsecureImages: true

fullnameOverride: "zookeeper"

image:
  registry: image-registry.openshift-image-registry.svc:5000
  repository: zoo-keeper/zookeeper
  tag: 3.9.5-ppc64le
  digest: ""
  pullPolicy: IfNotPresent

replicaCount: 1

auth:
  client:
    enabled: false
  quorum:
    enabled: false

persistence:
  enabled: false

resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

## Render manifest

```bash
helm template my-zookeeper bitnami/zookeeper   --version 13.8.7   -n zoo-keeper   -f values.yaml > rendered-zookeeper.yaml
```

Verify image:

```bash
grep -n "image:" rendered-zookeeper.yaml
```

Expected:

```text
image: image-registry.openshift-image-registry.svc:5000/zoo-keeper/zookeeper:3.9.5-ppc64le
```

Verify replicas:

```bash
grep -n "replicas:" rendered-zookeeper.yaml
```

Verify ServiceAccount:

```bash
grep -n "serviceAccountName:" rendered-zookeeper.yaml
```

## Install

```bash
helm install my-zookeeper bitnami/zookeeper   --version 13.8.7   -n zoo-keeper   -f values.yaml
```

Verify:

```bash
helm list -n zoo-keeper
```

Expected:

```text
my-zookeeper   zoo-keeper   deployed
```

---

# 5. OpenShift Runtime Validation

## Verify pod

```bash
oc get pods -n zoo-keeper -o wide
```

Expected:

```text
NAME          READY   STATUS    RESTARTS
zookeeper-0   1/1     Running   0
```

## Verify actual image

```bash
oc get pod zookeeper-0 -n zoo-keeper   -o jsonpath='{.spec.containers[0].image}{"\n"}'
```

Expected:

```text
image-registry.openshift-image-registry.svc:5000/zoo-keeper/zookeeper:3.9.5-ppc64le
```

## Verify ZooKeeper version

```bash
oc exec zookeeper-0 -n zoo-keeper -- zkServer.sh version
```

Observed:

```text
/opt/bitnami/java/bin/java
ZooKeeper JMX enabled by default
Using config: /opt/bitnami/zookeeper/bin/../conf/zoo.cfg
Apache ZooKeeper, version 3.9.5 2026-02-11 20:18 UTC
```

## Health check

```bash
oc exec zookeeper-0 -n zoo-keeper --   bash -c 'echo ruok | nc 127.0.0.1 2181'
```

Expected and observed:

```text
imok
```

---

# 6. Functional Validation

## Connect with ZooKeeper CLI

```bash
oc exec -it zookeeper-0 -n zoo-keeper -- zkCli.sh
```

Successful connection:

```text
Connecting to localhost:2181
Welcome to ZooKeeper!
JLine support is enabled
WatchedEvent state:SyncConnected type:None path:null
```

## Create ZNode

```text
create /ppc64le-test "ZooKeeper 3.9.5 Power validation"
```

Expected:

```text
Created /ppc64le-test
```

## Read ZNode

```text
get /ppc64le-test
```

Expected:

```text
ZooKeeper 3.9.5 Power validation
```

## Delete ZNode

```text
delete /ppc64le-test
```

Then exit:

```text
quit
```

---

# 7. Validation Summary

| Validation | Result |
|---|---|
| ppc64le image available | PASS |
| Podman image tagging | PASS |
| Podman registry authentication | PASS |
| Podman image push | PASS |
| OCP ImageStream | PASS |
| Helm deployment | PASS |
| Custom ppc64le image deployed | PASS |
| Pod running on OCP | PASS |
| ZooKeeper 3.9.5 runtime | PASS |
| Java runtime startup | PASS |
| Port 2181 health | PASS |
| `ruok` health check | PASS (`imok`) |
| ZooKeeper client connectivity | PASS |
| ZNode create | PASS |
| ZNode read | PASS |
| ZNode delete | PASS |

---

---

# 8. Conclusion

**ZooKeeper 3.9.5 was successfully validated on OpenShift using the ppc64le image.**

The custom image was successfully pushed to the OpenShift internal registry using **Podman**, deployed using **Bitnami ZooKeeper Helm chart 13.8.7**, and verified at runtime.

The validation confirmed:

- ZooKeeper 3.9.5 starts successfully on OpenShift.
- The custom `ppc64le` image is used by the running pod.
- ZooKeeper responds successfully to the `ruok` health check.
- ZooKeeper client connectivity is successful.
- ZNode create, read, and delete operations work as expected.
