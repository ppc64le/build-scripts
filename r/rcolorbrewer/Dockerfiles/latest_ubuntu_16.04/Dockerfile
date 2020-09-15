FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"
ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& git clone https://github.com/cran/RColorBrewer.git \
	&& cd RColorBrewer && git checkout 1.1-2 \
	&& cd .. \
	&& R CMD build RColorBrewer \
	&& R CMD INSTALL RColorBrewer \
	&& R CMD check RColorBrewer --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
