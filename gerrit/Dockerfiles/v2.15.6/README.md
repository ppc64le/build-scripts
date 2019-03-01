
Start Gerrit Code Review in its demo/staging out-of-the-box setup:

docker run -ti -p 8080:8080 -p 29418:29418 ibmcom/gerrit-ppc64le:2.15.6

Wait a few minutes until the Gerrit Code Review NNN ready message appears, where NNN is your current Gerrit version, then open your browser to http://localhost:8080 and you will be in Gerrit Code Review.

NOTE: If your docker server is running on a remote host, change 'localhost' to the hostname or IP address of your remote docker server.

