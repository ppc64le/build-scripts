FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
      && apt-get install git -y \
	&& git clone https://github.com/cran/gbm.git \
	&& cd gbm && git checkout 2.1.1 \
      && R -e 'install.packages("gbm",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check gbm \
	&& cd .. && rm -rf gbm \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
