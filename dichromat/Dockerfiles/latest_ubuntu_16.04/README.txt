dichromat (Rpackage)
Build and run the container:

$docker build -t dichromat .
$docker run -it --name=demo_dichromat dichromat

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

	>> library(dichromat)
	>> pal <- function(col, ...)
       image(seq_along(col), 1, matrix(seq_along(col), ncol = 1),
       col = col, axes = FALSE, ...)
       	>> opar <- par(mar = c(1, 2, 1, 1)) 
       	>> layout(matrix(1:6, ncol = 1))
      	>> pal(colorschemes$BrowntoBlue.10, main = "Brown to Blue (10)")
