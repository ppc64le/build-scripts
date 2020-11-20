Doxygen

Building and running the container:

$ docker build -t doxygen .
$ docker runt -it -v /doxygen-data:/doxygen-data doxygen

OUTPUT:

You will get help of the doxygen command.

you can pass other doxygen commands as well, and can also attach the
contaier using bash.
