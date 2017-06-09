Using and Testing Jetty:

Run the container as follows:

$ docker run -itd -p 8080:8080 jetty

You can also attach to container. 

Now you can see the default jetty server from browser with http://ip:8080

404 error, as no applications are yet deployed yet.

# Jetty which is being downloaded is jetty-home version which does not have demo project.

# If you want to try the demo project, download jetty-distribution from http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.4.2.v20170220/jetty-distribution-9.4.2.v20170220.tar.gz

# Untar it, and copy demo-base/webapps/async-rest.war from this to your JETTY_BASE. Refresh the web page.
 

