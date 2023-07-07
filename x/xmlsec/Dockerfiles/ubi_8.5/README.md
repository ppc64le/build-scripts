 * To Build XMLSec Image: 
```bash
docker build -t xmlsec:latest .
```

To create and run the container from the image built: 
```bash
docker run -it --name xmlsec_demo xmlsec:latest
```

To validate the xmlsec installation, execute the following inside the container:
```bash
xmlsec1 --version
```