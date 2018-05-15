Rcpp (Rpackage)

Build and run the container

$docker build -t rcpp .
$docker run -it --name=demo_rcpp rcpp

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(Rcpp)
>> showClass("C++Field")

OUTPUT:
Class "C++Field" [package "Rcpp"]

Slots:

Name:       .xData
Class: environment

Extends:
Class "envRefClass", directly
Class ".environment", by class "envRefClass", distance 2
Class "refClass", by class "envRefClass", distance 2
Class "environment", by class "envRefClass", distance 3, with explicit coerce
Class "refObject", by class "envRefClass", distance 3
