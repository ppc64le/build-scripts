FROM ppc64le/r-base 
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
      && apt-get install git -y \
      && git clone https://github.com/r-lib/R6.git \
      && cd R6 && git checkout v2.3.0 \
      && R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
      && R CMD check R6 --no-manual \
      && cd .. && rm -rf R6 \
      && apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
