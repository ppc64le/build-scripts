Apache-Freemarker

FreeMarker is a "template engine"; a generic tool to generate text output
(anything from HTML to auto generated source code) based on templates. It's
a Java package, a class library for Java programmers.

More Info:
https://freemarker.apache.org/docs/dgui_quickstart.html

Building and running the container:

$docker build -t freemarker .
$docker run -it --name=<name> freemarker

#NOTE: freemarker.jar will be available at /incubator-freemarker/build 
