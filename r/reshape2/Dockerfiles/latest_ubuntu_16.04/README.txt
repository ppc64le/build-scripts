Reshape2 (Rpackage)
Build and run the container:

$docker build -t reshape2 .
$docker run -it --name=demo_reshape2 reshape2

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(reshape2)
>> x <- c("a_1", "a_2", "b_2", "c_3")
>> vars <- colsplit(x, "_", c("trt", "time"))
>> vars
      
Output:
       trt time
       1   a    1
       2   a    2
       3   b    2
       4   c    3
