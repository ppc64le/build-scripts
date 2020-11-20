FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
        && apt-get install git -y \
        && git clone https://github.com/cran/httpRequest.git \
        && cd httpRequest && git checkout 0.0.10 \
        && cd .. \
        && R CMD build httpRequest \
        && R CMD INSTALL httpRequest \
        && R CMD check httpRequest --no-manual \
        && apt-get purge --auto-remove git -y

CMD ["/bin/bash"]


