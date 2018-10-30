FROM ppc64le/r-base 
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/reshape.git \
	&& cd reshape && git checkout 0.8.8 \
        && R -e 'install.packages("plyr",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& cd .. \
	&& R CMD build reshape \
	&& R CMD INSTALL reshape \
	&& R CMD check reshape --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
