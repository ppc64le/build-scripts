FROM ppc64le/r-base
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
        && apt-get install git texinfo texlive texlive-fonts-extra texlive-latex-extra -y \
        && R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("rbenchmark",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("RUnit",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
        && git clone https://github.com/RcppCore/Rcpp.git \
        && cd Rcpp && git checkout 0.12.16 \
        && cd .. \
        && R CMD build Rcpp \
        && R CMD check Rcpp --no-manual \
        && R CMD INSTALL Rcpp \
        && apt-get purge --auto-remove git -y

CMD ["/bin/bash"]

