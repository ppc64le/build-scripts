magrittr (Rpackage)

Build and run the container:

$docker build -t magrittr .
$docker run --name demo_magrittr -i -t magrittr /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:
```bash
> library(magrittr)
> iris %>%
+ extract(, 1:4) %>%
+ head
  Sepal.Length Sepal.Width Petal.Length Petal.Width
1          5.1         3.5          1.4         0.2
2          4.9         3.0          1.4         0.2
3          4.7         3.2          1.3         0.2
4          4.6         3.1          1.5         0.2
5          5.0         3.6          1.4         0.2
6          5.4         3.9          1.7         0.4
```
