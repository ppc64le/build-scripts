# Build script

The build script includes just the build and unit test execution. However,
in order to execute integration/e2e tests or do the validation, the build
and installation needs to be performed on either a k8s cluster or an ocp
cluster.

# Build and validation on OCP

There are two ways to install and validate camel-k operator from source on
an ocp cluster. One is via OLM and the other is non-OLM (passing an argument
`--olm=false` to kamel binary to skip OLM and use deployment files from source).

Please note that the integration/e2e test execution was tried only with the
non-OLM installation. So, the patches used for the build will remain the same
for both.

## Build

Here are the steps used to perform the build on an ocp cluster:
1. Login to the bastion node of the cluster and follow the same steps from
the build-script up until the checkout of v1.3.0 of camel-k i.e. upto

```
git checkout v1.3.0
```

2. Almost all the patches used in the build script are applicable here too. But
there are a few additional patches and minor change to one which are necessary
in order to get thing working on ocp cluster. The patches are categorized as
follows:
- patches that are used for UBI migration of the image

```
sed -i 's/openjdk11:slim/openjdk11:ubi/g' build/Dockerfile
sed -i 's/BaseImage = "adoptopenjdk\/openjdk11:slim"/BaseImage = "adoptopenjdk\/openjdk11:ubi"/g' pkg/util/defaults/defaults.go
```

- patches that are used to make sure that integration/e2e tests use non-olm
installation of the operator.

```
sed -i '/func Kamel(args ...string) \*cobra.Command {/a \\tif args[0] == "install" || args[0] == "uninstall"\{\n\t\targs = append\(strings.Fields\("--olm=false"), args...\)\n\t\}' e2e/support/test_support.go
sed -i '/func CreateKamelPod(ns string, name string, command ...string) error {/a \\tcommand = append\(strings.Fields\("--olm=false"), command...\)' e2e/support/test_support.go
```

OLM based installation may also work there, but that's not validated for integration
tests and that'll need too many arguments to be passed to the binary.

- patches that make sure that the camel-k:1.3.0 image is available/pulled through
the imagestream in the cluster.

```
sed -i 's/image: docker.io\/apache\/camel-k:1.3.0/image: image-registry.openshift-image-registry.svc:5000\/camelk\/camel-k:1.3.0/g' deploy/operator-deployment.yaml
sed -i 's/ImageName = "docker.io\/apache\/camel-k"/ImageName = "image-registry.openshift-image-registry.svc:5000\/camelk\/camel-k"/g' pkg/util/defaults/defaults.go
```

- patch that is used to replace docker with podman in the build.

```
sed -i 's/docker build -t \$(IMAGE_NAME):\$(VERSION) -f build\/Dockerfile ./podman build -t \$(IMAGE_NAME):\$(VERSION) -f build\/Dockerfile ./g' script/Makefile
```

- patch used to solve the "Invalid bundle" issue with catalog image creation
from the bundle image.

```
sed -i '/replaces: camel-k-operator.v1.2.0/d' config/manifests/bases/camel-k.clusterserviceversion.yaml
```

- patch used to make sure that the bundle specifies camel-k imagestream location.
Note that the build-script just removes the '-SNAPSHOT' part of the location.

```
sed -i 's/image: docker.io\/apache\/camel-k:1.3.0-SNAPSHOT/image: image-registry.openshift-image-registry.svc:5000\/camelk\/camel-k:1.3.0/g' config/manager/operator-deployment.yaml
```

3. Execute the following to build the kamel binary, run unit tests, build camel
1.3.0 image.

```
make controller-gen
make kustomize
make test
make package-artifacts
make images
```

4. Now, the following are needed to create the bundle image and push to docker.io.
It doesn't have to be docker.io specifically, can be any other registry, but not
the imagestream. The reason being, creating a catalog image with opm fails to find
the bundle image from imagestream. Also, note that the bundle build is needed for
OLM based installation/validation and can be skipped for non-OLM install.

```
wget https://github.com/operator-framework/operator-sdk/releases/download/v1.3.0/operator-sdk_linux_ppc64le
chmod +x operator-sdk_linux_ppc64le
mv operator-sdk_linux_ppc64le /usr/local/bin/operator-sdk
make bundle
operator-sdk bundle validate ./bundle
cd bundle
podman build -f Dockerfile -t docker.io/amitsadaphule/camel-k-bundle:1.3.0 .
cd ..
podman login docker.io -u <username> -p <password>
podman push docker.io/<repo>/camel-k-bundle:1.3.0
```

## Non OLM (installation, validation and e2e test execution)

Login to the cluster as kubeadmin, create new project, do other basic setup as:

```
oc login -u kubeadmin -p $(cat ~/openstack-upi/auth/kubeadmin-password)
oc new-project camelk || true
oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=camelk || true
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
echo $HOST
podman login -u kubeadm -p $(oc whoami -t) --tls-verify=false $HOST
```

Now, push the camel-k image to the imagestream and verify as:

```
podman tag docker.io/apache/camel-k:1.3.0 $HOST/camelk/camel-k:1.3.0
podman push $HOST/camelk/camel-k:1.3.0 --tls-verify=false
oc describe is camel-k -n camelk
```

1. Run integration tests

Now, just do the cluster setup related installations as:

```
./kamel install --cluster-setup --olm=false
```

Now, you can run the integration/e2e tests as:

```
make test-integration
```

Note that you may see some timeout failures for the tests in e2e/common/languages.
The error log may look something like:

```
=== RUN   TestRunSimpleJavaExamples/init_run_java
integration "initjava" created
--- FAIL: TestRunSimpleJavaExamples (223.00s)
    --- PASS: TestRunSimpleJavaExamples/run_java (121.24s)
    --- PASS: TestRunSimpleJavaExamples/run_java_with_properties (17.01s)
    --- FAIL: TestRunSimpleJavaExamples/init_run_java (77.43s)
panic: Unauthorized [recovered]
        panic: Unauthorized

...TRACE...

FAIL    github.com/apache/camel-k/e2e/common/languages  385.844s
FAIL
make: *** [Makefile:149: test-integration] Error 1
```

Those are mostly due to cluster instability. Individually executing
those tests from the `languages` directory shows success. Here are the
logs:

```
# go test -run TestRunSimpleGroovyExamples -timeout 60m -v ./e2e/common/languages -tags=integration -count=1
=== RUN   TestRunSimpleGroovyExamples
Camel K installed in namespace test-d54aec63-5237-4605-929e-9b242676b69e
=== RUN   TestRunSimpleGroovyExamples/run_groovy
integration "groovy" created
1 integration(s) deleted
=== RUN   TestRunSimpleGroovyExamples/init_run_groovy
integration "initgroovy" created
1 integration(s) deleted
--- PASS: TestRunSimpleGroovyExamples (169.18s)
    --- PASS: TestRunSimpleGroovyExamples/run_groovy (131.15s)
    --- PASS: TestRunSimpleGroovyExamples/init_run_groovy (11.54s)
PASS
ok      github.com/apache/camel-k/e2e/common/languages  169.221s

# go test -run TestRunSimpleJavaExamples -timeout 60m -v ./e2e/common/languages -tags=integration -count=1
=== RUN   TestRunSimpleJavaExamples
Camel K installed in namespace test-5a3864da-09e6-4d46-9408-e57c07bf8fe2
=== RUN   TestRunSimpleJavaExamples/run_java
integration "java" created
1 integration(s) deleted
=== RUN   TestRunSimpleJavaExamples/run_java_with_properties
integration "prop" created
1 integration(s) deleted
=== RUN   TestRunSimpleJavaExamples/init_run_java
integration "initjava" created
1 integration(s) deleted
--- PASS: TestRunSimpleJavaExamples (321.02s)
    --- PASS: TestRunSimpleJavaExamples/run_java (170.56s)
    --- PASS: TestRunSimpleJavaExamples/run_java_with_properties (14.44s)
    --- PASS: TestRunSimpleJavaExamples/init_run_java (86.63s)
PASS
ok      github.com/apache/camel-k/e2e/common/languages  321.050s

# go test -run TestRunSimpleJavaScriptExamples -timeout 60m -v ./e2e/common/languages -tags=integration -count=1
=== RUN   TestRunSimpleJavaScriptExamples
Camel K installed in namespace test-6df7edbd-67a8-4832-a446-b8ea1bcf7d5b
=== RUN   TestRunSimpleJavaScriptExamples/run_js
integration "js" created
1 integration(s) deleted
=== RUN   TestRunSimpleJavaScriptExamples/init_run_JavaScript
integration "initjs" created
1 integration(s) deleted
--- PASS: TestRunSimpleJavaScriptExamples (167.49s)
    --- PASS: TestRunSimpleJavaScriptExamples/run_js (132.13s)
    --- PASS: TestRunSimpleJavaScriptExamples/init_run_JavaScript (11.71s)
PASS
ok      github.com/apache/camel-k/e2e/common/languages  167.527s

# go test -run TestRunSimpleKotlinExamples -timeout 60m -v ./e2e/common/languages -tags=integration -count=1
=== RUN   TestRunSimpleKotlinExamples
Camel K installed in namespace test-27e0d4b9-a92c-464b-b78d-87c0383778ac
=== RUN   TestRunSimpleKotlinExamples/run_kotlin
integration "kotlin" created
1 integration(s) deleted
=== RUN   TestRunSimpleKotlinExamples/init_run_Kotlin
integration "initkts" created
1 integration(s) deleted
--- PASS: TestRunSimpleKotlinExamples (210.45s)
    --- PASS: TestRunSimpleKotlinExamples/run_kotlin (162.81s)
    --- PASS: TestRunSimpleKotlinExamples/init_run_Kotlin (18.60s)
PASS
ok      github.com/apache/camel-k/e2e/common/languages  210.494s

# go test -run TestRunPolyglotExamples -timeout 60m -v ./e2e/common/languages -tags=integration -count=1
=== RUN   TestRunPolyglotExamples
Camel K installed in namespace test-d978de5b-a9de-4923-8aa4-7eba8217af6a
=== RUN   TestRunPolyglotExamples/run_polyglot
integration "polyglot" created
1 integration(s) deleted
--- PASS: TestRunPolyglotExamples (263.64s)
    --- PASS: TestRunPolyglotExamples/run_polyglot (243.10s)
PASS
ok      github.com/apache/camel-k/e2e/common/languages  263.681s

# go test -run TestRunSimpleXmlExamples -timeout 60m -v ./e2e/common/languages -tags=integration -count=1
=== RUN   TestRunSimpleXmlExamples
Camel K installed in namespace test-25c03200-9de6-4324-b9fe-7177b303929a
=== RUN   TestRunSimpleXmlExamples/run_xml
integration "xml" created
1 integration(s) deleted
=== RUN   TestRunSimpleXmlExamples/init_run_xml
integration "initxml" created
1 integration(s) deleted
--- PASS: TestRunSimpleXmlExamples (184.91s)
    --- PASS: TestRunSimpleXmlExamples/run_xml (131.17s)
    --- PASS: TestRunSimpleXmlExamples/init_run_xml (12.02s)
PASS
ok      github.com/apache/camel-k/e2e/common/languages  184.948s

# go test -run TestRunSimpleYamlExamples -timeout 60m -v ./e2e/common/languages -tags=integration -count=1
=== RUN   TestRunSimpleYamlExamples
Camel K installed in namespace test-b0e6cd7c-49e3-4dea-8682-7e791d612eab
=== RUN   TestRunSimpleYamlExamples/run_yaml
integration "yaml" created
1 integration(s) deleted
=== RUN   TestRunSimpleYamlExamples/run_yaml_Quarkus
integration "yaml-quarkus" created
1 integration(s) deleted
=== RUN   TestRunSimpleYamlExamples/init_run_yaml
integration "inityaml" created
1 integration(s) deleted
--- PASS: TestRunSimpleYamlExamples (216.86s)
    --- PASS: TestRunSimpleYamlExamples/run_yaml (151.10s)
    --- PASS: TestRunSimpleYamlExamples/run_yaml_Quarkus (10.99s)
    --- PASS: TestRunSimpleYamlExamples/init_run_yaml (10.02s)
PASS
ok      github.com/apache/camel-k/e2e/common/languages  216.896s
```

2. Basic validation

If you just want to install and do basic validation execute:

```
# ./kamel install --cluster-setup --olm=false
Camel K cluster setup completed successfully
# ./kamel install --olm=false
Camel K installed in namespace camelk
```

Wait for the camel-k-operator-xx pod to come up and then run:

```
# ./kamel run examples/Sample.java
integration "sample" updated
```

You should see the sample-xx pod running after some time. It takes a few
minutes since a containerized build is performed in the background. You
should see something like this:

```
# oc get all -A | grep camel
camelk                                             pod/camel-k-kit-c05jft383n25ncj3fa3g-1-build                          0/1     Completed   0          111s
camelk                                             pod/camel-k-operator-597d487fbb-hkdm6                                 1/1     Running     0          5m28s
camelk                                             pod/sample-7dd4bf55bf-fbs9f                                           1/1     Running     0          26s
camelk                                             deployment.apps/camel-k-operator                         1/1     1            1           5m30s
camelk                                             deployment.apps/sample                                   1/1     1            1           27s
camelk                                             replicaset.apps/camel-k-operator-597d487fbb                         1         1         1       5m31s
camelk                                             replicaset.apps/sample-7dd4bf55bf                                   1         1         1       28s
camelk      buildconfig.build.openshift.io/camel-k-kit-c05jft383n25ncj3fa3g   Docker   Binary   1
camelk      build.build.openshift.io/camel-k-kit-c05jft383n25ncj3fa3g-1   Docker   Binary   Complete   About a minute ago   1m21s
camelk      imagestream.image.openshift.io/camel-k                            default-route-openshift-image-registry.apps.shivani-2-46.openshift.com/camelk/camel-k                            1.3.0                                                    13 minutes ago
camelk      imagestream.image.openshift.io/camel-k-kit-c05jft383n25ncj3fa3g   default-route-openshift-image-registry.apps.shivani-2-46.openshift.com/camelk/camel-k-kit-c05jft383n25ncj3fa3g   8223870
```

## OLM (installation and validation)

Login to the cluster as kubeadmin, create new project, do other basic setup as:

```
oc login -u kubeadmin -p $(cat ~/openstack-upi/auth/kubeadmin-password)
oc new-project camelk || true
oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=camelk || true
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
echo $HOST
podman login -u kubeadm -p $(oc whoami -t) --tls-verify=false $HOST
```

Now, we need to build the opm binary and also build the image
named `upstream-opm-builder` which is used by opm to build the
catalog image.

```
mkdir $GOPATH/src/github.com/operator-framework
cd $GOPATH/src/github.com/operator-framework
git clone https://github.com/operator-framework/operator-registry.git
cd operator-registry
git checkout v1.15.3
make build
export PATH=$PATH:`pwd`/bin
podman build -f upstream-opm-builder.Dockerfile -t quay.io/operator-framework/upstream-opm-builder:latest .
```

Now, perform the following steps to build the catalog image from the
previously built/pushed (to docker.io private repo) bundle image
and make that available as imagestream:

```
opm index add -u podman --bundles docker.io/<repo>/camel-k-bundle:1.3.0 --tag $HOST/camelk/camel-k-catalog:1.3.0 -p podman
podman push $HOST/camelk/camel-k-catalog:1.3.0 --tls-verify=false
```

Now, create a catalog-source.yaml file:

```
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: camel-k-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: image-registry.openshift-image-registry.svc:5000/camelk/camel-k-catalog:1.3.0
  displayName: Camel K catalog
  publisher: My publisher
```

and create the catalogsource and confirm creation as:

```
# oc create -f catalog-source.yaml
catalogsource.operators.coreos.com/camel-k-catalog created
# oc get catalogsources -A | grep camel
openshift-marketplace   camel-k-catalog       Camel K catalog       grpc   My publisher   41m
# oc get packagemanifest -A | grep camel
openshift-marketplace   knative-camel-operator                               Community Operators   21d
openshift-marketplace   red-hat-camel-k                                      Red Hat Operators     21d
openshift-marketplace   camel-k                                              Community Operators   21d
openshift-marketplace   camel-k                                              Camel K catalog       41m
```

Now, in order to install the operator using out custom catalog, run:

```
# cd $GOPATH/src/github.com/apache/camel-k
# ./kamel install --olm-source=camel-k-catalog --olm-source-namespace=openshift-marketplace --olm-channel=alpha
OLM is available in the cluster
Camel K installed in namespace camelk via OLM subscription
```

You can confirm the installation as:

```
# oc get all -A | grep camel
camelk                                             pod/camel-k-operator-7fbb745899-qflcb                                 1/1     Running     0          8s
openshift-marketplace                              pod/camel-k-catalog-m8f9g                                             1/1     Running     0          4m38s
openshift-marketplace                              service/camel-k-catalog                            ClusterIP      172.30.96.139    <none>                                 50051/TCP                      4m38s
camelk                                             deployment.apps/camel-k-operator                         1/1     1            1           11s
camelk                                             replicaset.apps/camel-k-operator-7fbb745899                         1         1         1       9s
camelk      imagestream.image.openshift.io/camel-k                      default-route-openshift-image-registry.apps.shivani-2-46.openshift.com/camelk/camel-k                         1.3.0                                                    8 hours ago
camelk      imagestream.image.openshift.io/camel-k-catalog              default-route-openshift-image-registry.apps.shivani-2-46.openshift.com/camelk/camel-k-catalog                 1.3.0                                                    6 hours ago
```

Now, the basic validation for Sample.java can be done as:

```
# ./kamel run examples/Sample.java
integration "sample" updated
```

You should see the sample-xx pod running after some time. It takes a few
minutes since a containerized build is performed in the background. You
should see something like this:

```
# oc get all -A | grep camel
camelk                                             pod/camel-k-operator-7fbb745899-mlxl6                                 1/1     Running     0          118s
camelk                                             pod/sample-7dd4bf55bf-cdbtt                                           1/1     Running     0          55s
openshift-marketplace                              pod/camel-k-catalog-klf7c                                             1/1     Running     0          4m52s
openshift-marketplace                              service/camel-k-catalog                            ClusterIP      172.30.134.18    <none>                                 50051/TCP                      4m51s
camelk                                             deployment.apps/camel-k-operator                         1/1     1            1           118s
camelk                                             deployment.apps/sample                                   1/1     1            1           57s
camelk                                             replicaset.apps/camel-k-operator-7fbb745899                         1         1         1       118s
camelk                                             replicaset.apps/sample-7dd4bf55bf                                   1         1         1       56s
camelk      imagestream.image.openshift.io/camel-k                      default-route-openshift-image-registry.apps.shivani-2-46.openshift.com/camelk/camel-k                         1.3.0                                                    2 days ago
camelk      imagestream.image.openshift.io/camel-k-catalog              default-route-openshift-image-registry.apps.shivani-2-46.openshift.com/camelk/camel-k-catalog                 1.3.0                                                    6 minutes ago
```

# References:
https://camel.apache.org/camel-k/latest/installation/openshift.html
https://medium.com/swlh/deploying-operator-webhooks-with-olm-be5612795840
http://krsacme.com/k8s-operator-custom-catalog/
https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/openshift-deployment
https://www.openshift.com/blog/custom-operator-registry-catalog-source-for-openshift-4.5
https://github.com/apache/camel-k/issues/1923
https://github.com/apache/camel-k/issues/1869

