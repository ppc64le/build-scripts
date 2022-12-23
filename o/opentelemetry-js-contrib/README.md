Pakckage    : opentelemetry-js-contrib
Version     : instrumentation-user-interaction-v0.32.0
Source repo : https://github.com/open-telemetry/opentelemetry-js-contrib
Tested on   : UBI 8.5


Summary :-

    To run test cases in mongoose instrumentation module, it requires first to run mongodb in the background.

1. Below is the test result for failing test case:

2 failing
  1) mongoose instrumentation
       "before all" hook for "instrumenting save operation with promise":
     Error: Timeout of 2000ms exceeded. For async tests and hooks, ensure "done()" is called; if returning a Promise, ensure it resolves. (/opentelemetry-js-contrib/plugins/node/instrumentation-mongoose/test/mongoose.test.ts)
      at listOnTimeout (node:internal/timers:559:17)
      at processTimers (node:internal/timers:502:7)

  2) mongoose instrumentation
       "after all" hook for "projection is sent to serializer":
     Error: Timeout of 2000ms exceeded. For async tests and hooks, ensure "done()" is called; if returning a Promise, ensure it resolves. (/opentelemetry-js-contrib/plugins/node/instrumentation-mongoose/test/mongoose.test.ts)
      at listOnTimeout (node:internal/timers:559:17)
      at processTimers (node:internal/timers:502:7)
	  
2.Please find the below instructions to build and run Mongodb in the backround:

With the below steps we are running mongodb dockerfile:
 # FROM ubuntu:20.04
 # RUN apt update -y && apt install -y mongodb-server mongodb-dev mongodb-clients mongodb mongo-tools && mkdir -p /data/db
 # EXPOSE 27017 28017
 # CMD ["/usr/bin/mongod", "--bind_ip_all"]

Now create an image from dockerfile:
 # docker build -t <IMAGE_NAME:tag> .

Then run a container using that image.
 # docker run -d -p 27017:27017 <IMAGE_NAME>/<IMAGE_ID>
  
Now next step is to use the above container-id/name and linked that container while running the actual container,
that we are going to used to build and test otel-js-contrib.
 e.g: docker run --name <container-name> --link <container-id/name(mongodb)> -it registry.access.redhat.com/ubi8/ubi:8.5 /bin/bash
 
3.#Finally run the script inside container 
Also need to export variable:
export MONGODB_HOST=<container_ip/container_name>
