Docker build command : docker build -t d3 .

Docker run command : docker run -it d3
Once inside the Docker image container check all installed dependencies of
d3 package, by using commands:
cd /d3
npm list | grep d3
