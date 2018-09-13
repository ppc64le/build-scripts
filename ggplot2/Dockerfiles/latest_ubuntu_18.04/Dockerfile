FROM ubuntu:18.04
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@bim.com>"
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
        && apt-get install -y git ed libxml2-dev libcairo2-dev libssl-dev libcurl4 libcurl4-openssl-dev curl libnlopt-dev r-base  \
        && R -e 'update.packages(ask = FALSE)' \
        && R -e 'install.packages("proto",dependencies= TRUE,repos="http://cran.rstudio.com/") ; install.packages("httr",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("git2r",dependencies= TRUE,repos="http://cran.rstudio.com/");install.packages("covr",dependencies= TRUE,repos="http://cran.rstudio.com/") ; install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("Rcpp",dependencies= TRUE,repos="http://cran.rstudio.com/");  install.packages("gdtools",dependencies= TRUE,repos="http://cran.rstudio.com/");  install.packages("svglite",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("maps",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("maptools",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("Hmisc",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("hexbin",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("mapproj",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("multcomp",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("quantreg",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("ggplot2movies",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
        && git clone https://github.com/ropensci/git2r.git \
        && R CMD build git2r && R CMD INSTALL git2r \
        && git clone https://github.com/cran/ggplot2.git \
        && cd ggplot2 && git checkout 3.0.0 \
        && R -e 'install.packages("ggplot2",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
        && R CMD check ggplot2 --no-manual \
        && apt-get purge --auto-remove git -y \
        && cd .. && rm -rf git2r ggplot2

CMD [ "/bin/bash" ]
