Docker build command : docker build -t nvd3 .

Docker run command : docker run -it nvd3
Once inside the Docker image container check all installed dependencies
of nvd3 package using commands:

cd /nvd3
npm list | grep nvd3
