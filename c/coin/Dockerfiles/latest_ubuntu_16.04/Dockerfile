FROM ppc64le/r-base
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/coin.git \
	&& cd coin && git checkout 1.2-2 \
        && R -e 'install.packages("coin",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check coin --no-manual \
	&& cd .. && rm -rf coin \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
