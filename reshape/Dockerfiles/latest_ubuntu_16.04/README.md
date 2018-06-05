reshape (Rpackage)

Build and run the container:

$docker build -t reshape .
$docker run --name demo_reshape -i -t reshape /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:

> library(reshape)
> df <- data.frame(a = LETTERS[sample(5, 15, replace=TRUE)], y = rnorm(15))
> combine_factor(df$a, c(1,2,2,1,2))
 [1] A A A B B B B B B A A B B B B
Levels: A B
> combine_factor(df$a, c(1:4, 1))
 [1] D A D C A C A A B A D B B A B
Levels: A B C D
>
> (f <- reorder(df$a, df$y))
 [1] D A D C E C E E B A D B B E B
attr(,"scores")
          A           B           C           D           E
-0.88361300 -0.04791613  0.23081767  0.70085216 -0.48791118
Levels: A E B C D
> percent <- tapply(abs(df$y), df$a, sum)
> combine_factor(f, c(order(percent)[1:3]))
 [1] Other B     Other Other A     Other A     A     C     B     Other C
[13] C     A     C
Levels: B A C Other
