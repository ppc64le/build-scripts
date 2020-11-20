tree (Rpackage)
Build and run the container:

$docker build -t tree .
$docker run -it --name=demo_tree tree

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

	>> library(tree)
	>> data(cpus, package="MASS")
       	>> cpus.ltr <- tree(log10(perf) ~ syct + mmin + mmax + cach
       		+ chmin + chmax, data=cpus)
       	>> cv.tree(cpus.ltr, , prune.tree)
       
Output:
      $size
      [1] 10  8  7  6  5  4  3  2  1
      
      $dev
      [1] 10.57894 13.12752 13.03053 13.35565 14.29250 14.55087 20.44650 20.52917
      [9] 43.65276
      
      $k
      [1]       -Inf  0.6808309  0.7243056  0.8000558  1.1607588  1.4148749  3.7783549
      [8]  3.8519002 23.6820624
      
      $method
      [1] "deviance"
      
      attr(,"class")
      [1] "prune"         "tree.sequence"
