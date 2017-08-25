This should be used with other openstack services

Docker build command
docker build -t nova .

Docker run command:
docker run --pid host --net host --privileged -p 8774:8774 -v /run:/run -v /lib/modules/:/lib/modules/:ro -v /var/lib/libvirt/images/nova/instances/:/var/lib/libvirt/images/nova/instances/ \
	-e DB_HOST=$db_ip \
        -e DOCKERHOST_IP=$eth0_address -e KEYSTONE_IP=$keystone_ip -e RABBITMQ_IP=$rabbitmq_ip -e GLANCE_IP=$glance_ip -dt nova
