## Steps to start and run the openVPN dockerfile 

#Build the OpenVPN server dockerfiles
    docker build -t openvpn .
   
    #Start the openVPN server container
    docker run --name=openvpn --privileged=true --net=host -dt  -p 1194:1194/udp -p 443:443 -p 943:943 -v /etc/openvpn:/etc/openvpn openvpn
   
    # set the var openvpn to the running container-ID 
    openvpn=`docker ps | grep openvpn | awk '{print $1}'`
    openvpn_ip=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' $openvpn`
   
    #Generate configuration and start the server
    docker exec -i $openvpn ovpn_genconfig -u udp://$PIC_BOX_EXTERNAL_IP:1194
    docker exec -i $openvpn ovpn_initpki   
    docker exec -i $openvpn ovpn_run &

## Steps to generate client profile file (to be run on the server) 

ip = <ipaddress of the client>
sudo docker exec -i $openvpn easyrsa build-client-full $ip nopass
# create the profile file named <ip-addr>.ovpn 
sudo docker exec -i $openvpn ovpn_getclient $ip > $ip.ovpn

## Steps to connect from client 
1) Get the openVPN client up 
2) Import the above generated profile file from "Connection Profiles +" , give path of the file and click on
the "import" button 
3) Once done ,it lists the profile being imported, now click on it
4) It should connect without being asked for any credentials