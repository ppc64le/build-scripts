# Deploy activemq-artemis-operator on power
1.Execute following commands:
```bash
source build.sh
```
2.check imagestream of ocp registry:
```bash
oc get is
oc describe <name>
```
3.Modify/Override default images in operator.yaml and broker_activemqartemis_cr.yaml 
Replace activemq-artemis-operator and activemq-artemis-broker-kubernetes images using our build images.
```bash
vi activemq-artemis-operator/deploy/operator.yaml
vi deploy/crs/broker_activemqartemis_cr.yaml
```
6.Create a new project:
```bash
 oc new-project <project_name>
 ```
 7.Switch to an existing project:
 ```bash
 oc project <project_name>
 ```
 8.Create the service account in your project
 ```bash
 oc create -f deploy/service_account.yaml
 ```
 9.Create the role in your project.
 ```bash
 oc create -f deploy/role.yaml
 ```
 10.Create the role binding in your project.
 ```bash
 oc create -f deploy/role_binding.yaml
 ```
 11. Deploy the main broker CRD.
 ```bash
 oc create -f deploy/crds/broker_activemqartemis_crd.yaml
 ```
 12.Deploy the addressing CRD.
 ```bash
 oc create -f deploy/crds/broker_activemqartemisaddress_crd.yaml
 ```
 13.Deploy the scaledown controller CRD.
 ```bash
 oc create -f deploy/crds/broker_activemqartemisscaledown_crd.yaml
 ```
 14.Deploy the Operator.
 ```bash
 oc create -f deploy/operator.yaml
 ```
 15.Deploy Activemqartemis CR
 ```bash
 oc create -f deply/crs/broker_activemqartemis_cr.yaml
 ```
