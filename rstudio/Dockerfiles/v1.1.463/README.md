To Create Image from the Docker file :
--------------------------------------
#cd <Path containing Dockerfile>
#docker build -t  <Name Of Image> .


To run the container use the Below Command :
--------------------------------------------
docker run -d -p 8787:8787 <name of the Image>


To open RStudio GUI:
--------------------
Run http://<IPAddr>:8787/ 
Default username and password is created:
     .username: test
     .password: test
