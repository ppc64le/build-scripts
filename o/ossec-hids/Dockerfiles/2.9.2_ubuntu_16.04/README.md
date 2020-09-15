This is a README file for the ossce-hids Dockerfile

The Dockerfile installs ossec-hids based on the configuration parameters
provided in the preloaded-vars.conf file that comes with the Dockerfile.
Currently this file has default configuration parameters set.

Building the Container
----------------------
The docker container will need to be re-built for any configuration 
changes made to the .conf file to take effect.

The command to re-build the container is:
"docker build -t ossec-server_ppc64le:latest ."

Note that Dockerfile has been tested to work without issues with the 
default "server" and "local" configurations only.


Running the container
---------------------

The start_ossec_hids.sh script provided with the Dockerfile is used
at run time to start the ossec-hids server. It also adds a default agent 
which is a pre-requisite for the ossec-remoted service that communicates 
with remote agents to start successfully.

The command to start the docker container is:
"docker run --name ossec-server --privileged=True -P -d -t ossec-server_ppc64le:latest"

This should start the ossec-server with the default ports 1514 and 514
mapped to random ports on the host.

The following command can be used to cross-verify that the container is
up and running:
"docker ps -a"

Expected output of the above command is in the following form:
785c3c7657f1        ossec-server_ppc64le:latest   "sh start_ossec_hids   47 minutes ago      Up 47 minutes       0.0.0.0:32778->514/tcp, 0.0.0.0:32779->1514/tcp   ossec-server


Managing agents / services in a running container
-------------------------------------------------

Once the container is running, the following command can be used 
to manage (add/remove/extract keys) agents.
"docker exec -it ossec-server /srv/ossec/bin/manage_agents"

This command runs in interactive mode.

ossec servecise can also be managed using the ossec-control command as:
"docker exec -it ossec-server /srv/ossec/bin/ossec-control status"
"docker exec -it ossec-server /srv/ossec/bin/ossec-control start"
"docker exec -it ossec-server /srv/ossec/bin/ossec-control stop"


Stopping the container
----------------------

The container can be stopped using the following command:
docker stop <CONTAINER ID>



