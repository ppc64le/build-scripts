R6 (Rpackage)

Build and run the container:

$docker build -t r6 .
$docker run --name demo_r6 -i -t r6 /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:
```bash
> library(R6)
> class_generator <- R6Class()
> object <- class_generator$new()
> is.R6Class(class_generator)
[1] TRUE
> is.R6(class_generator)
[1] FALSE
> is.R6Class(object)
[1] FALSE
> is.R6(object)
[1] TRUE
```
