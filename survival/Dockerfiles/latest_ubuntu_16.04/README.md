Survival (Rpackage)

Build and run the container

$docker build -t survival .
$docker run -it --name=demo_survival survival

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(survival)
>> fit <- coxph(Surv(futime, fustat) ~ resid.ds *rx + ecog.ps, data = ovarian)
>> anova(fit)

OUTPUT:

Analysis of Deviance Table
 Cox model: response is Surv(futime, fustat)
Terms added sequentially (first to last)

             loglik  Chisq Df Pr(>|Chi|)
NULL        -34.985
resid.ds    -33.105 3.7594  1    0.05251 .
rx          -32.269 1.6733  1    0.19582
ecog.ps     -31.970 0.5980  1    0.43934
resid.ds:rx -30.946 2.0469  1    0.15251
---
Signif. codes:  0 â*â.001 ââ.01 â 0.05 â 0.1 â 1
