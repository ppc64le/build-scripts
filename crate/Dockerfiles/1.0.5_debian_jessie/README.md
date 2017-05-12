#Instructions for crate package.

1) First create a docker image using following command :

	docker build -t crate .


2) Run image in detach mode :

	 docker run -d -p 4200:4200 -p 4300:4300 crate crate
	 Crate's default ports 4200 (HTTP) and 4300 (Transport protocol).

3) Test
	curl http://<localhost>:4200 or open it on brower to view crate portal.


