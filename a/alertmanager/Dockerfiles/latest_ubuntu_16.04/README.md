Alertmanager

Build and Run the container

$docker build -t alertmanager .
$docker run -d -p 9093:9093 alertmanager 

Now you can access the alertmanager from browser at
http://vm_ip:9093

or 

Run the container as follows:

$docker run -it -p 9093:9093 alertmanager -h

You will get all the help for alertmanager
