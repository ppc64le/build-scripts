logging(Rpackage)
Build and run the container:

$docker build -t logging.
$docker run -it --name=demo_ logging logging

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(logging)
>> getLogger()

Output:
       Reference class object of class "Logger"
       Field "name":
       [1] ""
       Field "handlers":
       $writeToConsole
       <environment: 0x10008dee7f0>
       
       Field "level":
       INFO
         20
