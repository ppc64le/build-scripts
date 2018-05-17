FROM node:8
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

RUN useradd -ms /bin/bash strong-pm \
    && chown -R strong-pm:strong-pm /usr/local \
    && su strong-pm -c "npm install -g strong-pm && npm cache clear --force"

# Set up some semblance of an environment
WORKDIR /home/strong-pm
ENV HOME=/home/strong-pm

# Run as non-privileged user inside container
USER strong-pm

# Expose strong-pm port
EXPOSE 8701 3000 3001 3002 3003

ENTRYPOINT ["/usr/local/bin/sl-pm", "--base", ".", "--listen", "8701"]
