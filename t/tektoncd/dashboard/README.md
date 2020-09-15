<h1>Building Dashboard Image(v0.2.0)</h1>
Add the <a href="./Dockerfile.ubi">Dockerfile.ubi</a> to root directory of <a href="https://github.com/tektoncd/dashboard/tree/v0.2.0">Tekton Dashboard</a>.

To build image, run below command from the root directory of <a href="https://github.com/tektoncd/dashboard/tree/v0.2.0">Tekton Dashboard</a>
```
docker build -t tekton_dashboard:v0.2.0 -f Dockerfile.ubi .
docker images | grep tekton_dashboard
```
