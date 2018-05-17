FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/survival.git \
	&& cd survival && git checkout 2.42-3 && cd .. \
	&& R CMD build survival  --no-build-vignettes \
	&& R CMD check survival --no-build-vignettes --no-manual \
	&& R CMD INSTALL survival \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
