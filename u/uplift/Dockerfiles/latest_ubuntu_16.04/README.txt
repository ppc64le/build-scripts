Uplift (Rpackage)
Build and run the container:

$docker build -t uplift .
$docker run -it --name=demo_uplift uplift

Test the working of uplift:
Inside the container type R and enter the R shell. Execute following code:

>>library(uplift)
>>set.seed(12345)
>>dd <- sim_pte(n = 1000, p = 20, rho = 0, sigma = sqrt(2), beta.den = 4)
>>dd$treat <- ifelse(dd$treat == 1, 1, 0)
>>checkBalance(treat ~ X1 + X2 + X3 + X4 + X5 + X6 , data = dd)

Output of last command will be:
            strata  unstrat                                                            
            stat    treat=0  treat=1 adj.diff adj.diff.null.sd std.diff     z          
       vars                                                                            
       X1          0.01152  -0.00596 -0.01748         0.06006  -0.01840 -0.29103       
       X2          0.03160  -0.02812 -0.05972         0.06236  -0.06057 -0.95778       
       X3          0.01145  -0.02242 -0.03387         0.06355  -0.03370 -0.53303       
       X4          0.01533  -0.03551 -0.05083         0.06370  -0.05046 -0.79801       
       X5          -0.06440 0.02370  0.08810          0.06153  0.09060  1.43175        
       X6          0.02237  -0.02177 -0.04414         0.06308  -0.04425 -0.69980       
       ---Overall Test---
               chisquare df p.value
       unstrat      4.54  6   0.604
       ---
       Signif. codes:  0 '***' 0.001 '** ' 0.01 '*  ' 0.05 '.  ' 0.1 '   ' 1
