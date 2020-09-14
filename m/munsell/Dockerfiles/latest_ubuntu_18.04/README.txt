munsell (Rpackage)
Build and run the container:

$docker build -t munsell .
$docker run -it --name=demo_munsell munsell

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(munsell)

Output: 
	[1] "5Y 2/4"

       >> complement("5PB 2/4")
       >> plot_mnsl(c(cols, complement(cols)))
