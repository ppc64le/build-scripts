nnet (Rpackage)

Build and run the container:

$docker build -t nnet .
$docker run --name demo_nnet -i -t nnet /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:

> library(nnet)
> options(contrasts = c("contr.treatment", "contr.poly"))
> library(MASS)
> example(birthwt)

brthwt> bwt <- with(birthwt, {
brthwt+ race <- factor(race, labels = c("white", "black", "other"))
brthwt+ ptd <- factor(ptl > 0)
brthwt+ ftv <- factor(ftv)
brthwt+ levels(ftv)[-(1:2)] <- "2+"
brthwt+ data.frame(low = factor(low), age, lwt, race, smoke = (smoke > 0),
brthwt+            ptd, ht = (ht > 0), ui = (ui > 0), ftv)
brthwt+ })

brthwt> options(contrasts = c("contr.treatment", "contr.poly"))

brthwt> glm(low ~ ., binomial, bwt)

Call:  glm(formula = low ~ ., family = binomial, data = bwt)

Coefficients:
(Intercept)          age          lwt    raceblack    raceother    smokeTRUE
    0.82302     -0.03723     -0.01565      1.19241      0.74068      0.75553
    ptdTRUE       htTRUE       uiTRUE         ftv1        ftv2+
    1.34376      1.91317      0.68020     -0.43638      0.17901

Degrees of Freedom: 188 Total (i.e. Null);  178 Residual
Null Deviance:      234.7
Residual Deviance: 195.5        AIC: 217.5
