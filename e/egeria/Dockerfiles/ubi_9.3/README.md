* To Build Egeria Image: 
```bash
docker build -t egeria:latest .
```

To create and run the container from the image built: 

* Run the egeria user interface:
```bash
docker run --name egeria_cont -p 9443:9443 -d egeria:latest /bin/bash -c "java -jar /deployments/server/server-chassis-spring-*.jar"

docker run -d --name egeria_ui -p 8443:8443 egeria:latest /bin/bash -c "java -jar /deployments/user-interface/ui-chassis-spring-*.jar"
```

To view Egeria UI, visit `https://<host-ip>:9443/swagger-ui.html`

Reference:
- https://egeria-project.org/education/tutorials/docker-tutorial/overview/#downloading-the-egeria-docker-image
- https://hub.docker.com/r/odpi/egeria#Useage