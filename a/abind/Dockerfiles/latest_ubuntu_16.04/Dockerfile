FROM ppc64le/r-base
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/abind.git \
	&& cd abind && git checkout 1.4-5 && cd .. \
        && R CMD build abind \
	&& R CMD check abind --no-manual \
	&& R CMD INSTALL abind \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
