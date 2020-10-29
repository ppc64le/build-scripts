# Deploy eclipse-che on power using chectl
1.Execute following commands:
```bash
source build.sh
```
2.check imagestream of ocp registry:
```bash
oc get is
oc describe <name>
```
3.Modify/Override default images(che-server,keyclaok,devfile-registry,plugin registry,postgres) in CR files of chectl
```bash
cd /opt/chectl/templates/che-operator/crds
```
4.Run chectl command:
```bash
chectl server:start --che-operator-image=<specify the operator image from imagestream> --che-operator-cr-yaml=<specify cr file path location> --platform=openshift --installer=operator
```
Example:
chectl server:start --che-operator-image=image-registry.openshift-image-registry.svc:5000/che/che-operator@sha256:773f92f1ca3efe8c0a55e2ba3296705f2ffdb18875e8ca6b1eb524d95976cac8 --che-operator-cr-yaml=/home/chectl/templates/che-operator/crds/org_v1_che_cr.yaml --platform=openshift --installer=operator

