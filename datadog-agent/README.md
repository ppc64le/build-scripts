# Build datadog-agent

In order to build datadog-agent, please copy the contents of current directory to a directory
on the build machine.

Enable execute permissions for the build script and run it as:

```
# chmod +x datadog_rhel8.2.sh
# ./datadog_rhel8.2.sh
```

You can run the datadog-agent with 
```
./bin/agent/agent run -c bin/agent/dist/datadog.yaml
```