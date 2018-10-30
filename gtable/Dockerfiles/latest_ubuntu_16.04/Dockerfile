FROM ppc64le/r-base
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

RUN apt-get update \
      && apt-get install git -y \
      && git clone https://github.com/hadley/gtable.git \
      && cd gtable && git checkout v0.2.0 \
      && R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
      && R CMD check gtable --no-manual \
      && cd .. && rm -rf gtable \
      && apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
