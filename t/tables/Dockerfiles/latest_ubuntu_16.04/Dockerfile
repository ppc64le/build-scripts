FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
        && git clone https://github.com/cran/tables.git \
        && cd tables && git checkout 0.8.3 \
        && R -e 'install.packages("tables",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
        && cd .. && rm -rf tables \
        && apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
