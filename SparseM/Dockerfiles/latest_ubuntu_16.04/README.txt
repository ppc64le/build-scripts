SparseM (Rpackage)
Build and run the container:

$docker build -t sparsem .
$docker run -it --name=demo_sparsem sparsem

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(SparseM)
>> data(lsq)
>> class(lsq)
       
Output:
      [1] "matrix.csc.hb"
      attr(,"package")
      [1] "SparseM"
