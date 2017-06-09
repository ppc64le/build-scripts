#Instructions for collectd package.

1) First create a docker image using following command :

	docker build -t collectd .


2) Run image in detach mode :

	 docker run --name some-collectd -d collectd

3) To test we can start,stop and restart the service  
	 service collectd restart

	 service collectd start

	 service collectd stop
