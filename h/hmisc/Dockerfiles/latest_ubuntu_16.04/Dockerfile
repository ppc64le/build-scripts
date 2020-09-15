FROM ubuntu:18.04
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

ENV DEBIAN_FRONTEND="noninteractive"
ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update -y \
        && apt-get install -y git r-base libnlopt-dev ed libssl-dev libcurl4-openssl-dev \
        && git clone https://github.com/cran/Hmisc.git \
        && cd Hmisc && git checkout 4.1-1 && cd .. \
        && R -e 'install.packages("proto",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("xml2",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("Formula",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("ggplot2",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("latticeExtra",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("acepack",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("gtable",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("gridExtra",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("data.table",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("htmlTable",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("viridis",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("htmltools",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("base64enc",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("rms",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("mice",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("ff",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("ffbase",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("tables",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("plotly",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
        && R CMD build --keep-empty-dirs --no-resave-data --no-build-vignettes  Hmisc \
        && R CMD INSTALL Hmisc \
        && R CMD check  Hmisc --no-manual --no-vignettes \
        && apt-get purge --auto-remove git -y \
        && rm -rf Hmisc

CMD ["/bin/bash"]

