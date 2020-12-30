# Build Datadog Agent 7.24.0 docker image

Please find the instructions to build CentOS 8 based docker image of
Datadog Agent 7.24.0 below. 

## CentOS 8 container

Build the image by executing the following command:

```
# docker build -f Dockerfile -t datadog-agent-ppc64le:7.24.0 .
```

Run the Datadog Agent container by executing the following command:

```
# docker run -it --name dd-agent datadog-agent-ppc64le:7.24.0 "/bin/bash"
```

## Activate the Python 3.8 virutal environment inside Datadog Agent container
```
# source $PYTHON_VENV/bin/activate
```

## Check the agent version
Now you can access the agent by calling `agent` command.
Check version:
`# agent version`


