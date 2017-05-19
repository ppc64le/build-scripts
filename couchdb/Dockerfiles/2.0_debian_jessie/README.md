Couchdb dockerfile (for ver. 2.0.0)


Build docker image

1) Place relevant files in a folder, say ~/couchdb (docker-entrypoint.sh, Dockerfile, local.ini, supervisord.conf, vm.args)

2) cd ~/couchdb

3) docker build -t ppc64le/couchdb:2.0.0 


Test docker image

1) Start a couchdb instance

   docker run -d --name my-couchdb ppc64le/couchdb:2.0.0 

2) Use the instance

   docker run --name my-couchdb-app --link my-couchdb:couch ppc64le/couchdb:2.0.0
