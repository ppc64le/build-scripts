FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& R -e 'install.packages("svUnit",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/cran/logging.git \
	&& cd logging && git checkout 0.7-103 \
	&& cd .. \
	&& R CMD build logging \
	&& R CMD INSTALL logging \
	&& R CMD check logging --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
