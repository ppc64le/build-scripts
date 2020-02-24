# Steps for creating che-operator docker image on POWER

1. Build this on machine with latest docker

2. Execute following commands:

```bash
cd ~/go/src
git clone -b 7.4.1 https://github.com/eclipse/che-operator.git
```

3. Download following file from this page:
- Dockerfile

4. Execute following commands:
```bash
cp Dockerfile che-operator
cd che-operator
```

5.Build the image:
```bash
docker build -t <repository>/che-operator-ubi8-ppc64le .
docker push <repository>/che-operator-ubi8-ppc64le
```
