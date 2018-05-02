Akima (Rpackage)
Build and run the container:
$docker build -t akima .
$docker run -it --name=demo_akima akima

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(akima)
>> data(akima760)
>> akima.bic <- bicubic(akima760$x,akima760$y,akima760$z,
	  seq(0,8,length=50), seq(0,10,length=50))
>> plot(sqrt(akima.bic$x^2+akima.bic$y^2), akima.bic$z, type="l")
