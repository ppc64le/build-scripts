FROM ppc64le/r-base 
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

RUN apt-get update \
      && apt-get install git -y \
      && git clone https://github.com/tidyverse/magrittr.git \
      && cd magrittr && git checkout v.1.5 \
      && R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
      && R CMD check magrittr --no-manual \
      && cd .. && rm -rf magrittr \
      && apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
