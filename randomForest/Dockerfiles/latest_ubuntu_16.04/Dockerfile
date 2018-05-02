FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/randomForest.git \
	&& cd randomForest && git checkout 4.6-12 \
	&& cd .. \
	&& R CMD build randomForest \
	&& R CMD INSTALL randomForest \
	&& R CMD check randomForest --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
