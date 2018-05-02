Coin (Rpackage)
Build and run the container:

$docker build -t coin.
$docker run -it --name=demo_coin coin

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(coin)
>> boxplot(elevel ~ alength, data = alpha)
>> kruskal_test(elevel ~ alength, data = alpha)

Output of last command will be:
       
               Asymptotic Kruskal-Wallis Test
       
       data:  elevel by alength (short, intermediate, long)
       chi-squared = 8.8302, df = 2, p-value = 0.01209
