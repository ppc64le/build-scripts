#Build the docker image 

docker build -t r-base:3.6.1 .


#Run the docker image (this will launch the R-shell)

docker run -t r-base:3.6.1
