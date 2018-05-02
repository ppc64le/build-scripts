modeltools (Rpackage)
Build and run the container:

$docker build -t modeltools .
$docker run -it --name=demo_ modeltools modeltools

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

	>> library(modeltools)
	>> data("iris")
       	>> me <- ModelEnvFormula(Species+Petal.Width~.-1, data=iris,
       		subset=sample(1:150, 10))
       	>> me1 <- MEapply(me, FUN=list(designMatrix=scale,
       		response=function(x) sapply(x, as.numeric)))
	>> me@get("designMatrix")
      
Output:
       Sepal.Length Sepal.Width Petal.Length
       78           6.7         3.0          5.0
       68           5.8         2.7          4.1
       95           5.6         2.7          4.2
       54           5.5         2.3          4.0
       36           5.0         3.2          1.2
       128          6.1         3.0          4.9
       143          5.8         2.7          5.1
       131          7.4         2.8          6.1
       20           5.1         3.8          1.5
       5            5.0         3.6          1.4
       attr(,"assign")
       [1] 1 2 3
