How to use Consul Container?

1.	Verifying the consul binary:
$consul
2.	Consul agent in development mode: 
$docker run -dP --name=agent1 consul

3.	You can list all the running agents with following command:
$docker exec -i agent1 consul members
4.	You can also get the detailed information of all the node from outside the container as follows:
$curl localhost:MAPPED_PORT/v1/catalog/nodes
Where MAPPED_PORT is the host port to which 8500 of container is mapped.
 
5.	Consul agent in normal mode: 
$docker run -dP .name=agent1 consul agent 

6.	By default the development mode has UI enabled, but if you want to run it in non-development mode you have to enable the UI with -ui  option as follows:
$ docker run -dP --name=agent1 consul agent -ui
Now yo can access the UI from browser with following url:
http://VM_IP:MAPPED_PORT    
Where, MAPPED_PORT is the host port which is mapped to 8500 of container


