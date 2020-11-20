Docker build command:
docker build --rm=true --build-arg ARCH=-"ppc64el" -t ansible-runner .

Docker run command:
docker run --rm -e RUNNER_PLAYBOOK=test.yml ansible-runner
