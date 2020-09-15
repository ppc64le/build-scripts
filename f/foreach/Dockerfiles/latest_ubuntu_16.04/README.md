Foreach (Rpackage)

Build and run the container:

$docker build -t foreach .
$docker run --name demo_foreach -i -t foreach /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:

>  library(foreach)
> x <- foreach(i=1:3) %do% sqrt(i)
> x

Output of previous command is :

[[1]]
[1] 1

[[2]]
[1] 1.414214

[[3]]
[1] 1.732051

