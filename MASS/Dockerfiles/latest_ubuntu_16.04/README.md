MASS (Rpackage)

Build and run the container:

$docker build -t MASS .
$docker run -it -name=demo_MASS MASS .

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(MASS)
>> m1 <- glm.nb(Days ~ Eth*Age*Lrn*Sex, quine, link = log)
>> m2 <- update(m1, . ~ . - Eth:Age:Lrn:Sex)
>> anova(m2, m1)

Output of the last command will be :

Likelihood ratio tests of Negative Binomial Models

Response: Days
                                                                                                                                      Model
1 Eth + Age + Lrn + Sex + Eth:Age + Eth:Lrn + Age:Lrn + Eth:Sex + Age:Sex + Lrn:Sex + Eth:Age:Lrn + Eth:Age:Sex + Eth:Lrn:Sex + Age:Lrn:Sex
2                                                                                                                     Eth * Age * Lrn * Sex
    theta Resid. df    2 x log-lik.   Test    df LR stat.   Pr(Chi)
1 1.90799       120       -1040.728
2 1.92836       118       -1039.324 1 vs 2     2 1.403843 0.4956319
