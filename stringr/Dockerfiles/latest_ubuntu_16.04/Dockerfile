FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
      && apt-get install git -y \
      && git clone https://github.com/tidyverse/stringr.git \
      && cd stringr && git checkout v1.3.0 \
      && R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
      && R CMD check stringr --no-manual \
      && cd .. && rm -rf stringr \
      && apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
