Docker build command: 
$docker build -t strongloop .

docker run command: 
$docker run --name=strongloop -itd -p 41629:41629 strongloop

You can now access the strongloop dashboard from browser by typing http://vm_ip:41629


Or you can also enter the container with shell as follows:

$docker exec -it strongloop bash 
