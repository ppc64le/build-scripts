
# Steps for creating che-server docker image on POWER

1. Ensure that maven with version > 3.1.1 is available

2. Execute following commands:

```bash
git clone -b 7.5.1 https://github.com/eclipse/che.git
cd che/assembly/assembly-main/
mvn clean install
cd ../../dockerfiles/che/
```

3. Download following file from this page:
- Dockerfile

4. Execute following command:
```bash
./build.sh
```

5. Build the image:
```bash
docker build -t <repository>/che-server-ubi8-ppc64le .
docker push <repository>/che-server-ubi8-ppc64le
```
