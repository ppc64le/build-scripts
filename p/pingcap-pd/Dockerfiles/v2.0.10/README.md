How to use PD container?

1.	Pull the pd docker container.

2.	Export the variable “HostIP”, to the IP address of the host machine on which you are going to run the container.

3.	Run the container using following command:

	$docker run -d -p 2379:2379 -p 2380:2380 --name pd  ibmcom/pd-server-ppc64le \
           --client-urls="http://0.0.0.0:2379"  \
           --advertise-client-urls=http://${HostIP}:2379 \
           --peer-urls=http://0.0.0.0:2380 \
           --advertise-peer-urls=http://${HostIP}:2380

4.	To check if the service is running and see the PD members use curl as follows:
	$curl ${HostIP}:2379/v2/members

	You will get output something as follows:
	{"members":[{"id":"4b9991258bf7bc1a","name":"pd","peerURLs":["http://10.77.67.135:2380"],"clientURLs":["http://10.77.67.135:2379"]}]}

