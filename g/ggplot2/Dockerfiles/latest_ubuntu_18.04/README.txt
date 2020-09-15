Ggplot2 (Rpackage)
Build and run the container:

$docker build -t ggplot .
$docker run -it --name=demo_ggplot2 ggplot2

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>>library(ggplot2)
>>base <- ggplot(mpg, aes(displ, hwy)) + geom_point()
>>base + geom_smooth()

Output of last command will be:
       
       `geom_smooth()` using method = 'loess'
