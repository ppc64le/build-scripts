Formula (Rpackage)

Build and run the container:

$docker build -t formula .
$docker run --name demo_formula -i -t formula /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:
 ```bash
> library(Formula)
> f1 <- y ~ x1 + x2 | z1 + z2 + z3
> F1 <- Formula(f1)
> class(F1)
[1] "Formula" "formula"
> length(F1)
[1] 1 2
```
