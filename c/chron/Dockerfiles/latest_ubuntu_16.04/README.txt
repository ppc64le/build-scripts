chron (Rpackage)
Build and run the container:
$docker build -t chron .
$docker run -it --name=demo_chron chron

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(chron)
>> format(chron(0, 0), c("yy/m/d", "h:m:s"), sep = "T", enclose = c("", ""))
      
Output of last command will be:

       [1] "1970/Jan/01T00:00:00"
