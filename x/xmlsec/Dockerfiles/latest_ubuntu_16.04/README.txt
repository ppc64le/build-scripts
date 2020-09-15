Xmlsec
Build and run the container:

$docker build -t xmlsec .
$docker run -it --name=demo_xmlsec xmlsec 

To validate the xmlsec installation type following inside the container:
$xmlsec1 --version
