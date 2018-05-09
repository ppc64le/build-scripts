zlibbioc (Rpackage)

Build and run the container:

$docker build -t zlibbioc .
$docker run --name demo_zlibbioc -i -t zlibbioc /bin/bash

Test the working of Container:
Inside the container type R and enter the R shell. Execute following commands:

>> library(zlibbioc)
>>pkgconfig("PKG_CFLAGS")


Output of the last command will be :

-I"/usr/local/lib/R/site-library/zlibbioc/include"

>>pkgconfig("PKG_LIBS_static")


Output of the last command will be :

"/usr/local/lib/R/site-library/zlibbioc/libs/libzbioc.a">
