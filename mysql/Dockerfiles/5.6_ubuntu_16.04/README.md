MySQL is a widely used, open-source relational database management system (RDBMS).

Supported Tags:
5.6

Building the docker image:
docker build -t ppc64le/mysql:5.6 .

Starting the container:
docker run -d -t -p 3306:3306 ppc64le/mysql:5.6
