# Install the app dependencies in a full Node docker image
FROM registry.access.redhat.com/ubi8/nodejs-12

USER root

RUN yum -y clean all && yum repolist \
  && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && yum -y install python2 \
  && ln -s $(which python2) /usr/local/bin/python \
  && echo "Finished installing dependencies"

RUN groupadd node && useradd -r -g node node  -m -d /home/node/

# Install stack dependencies
WORKDIR /project
COPY ./package*.json ./
RUN npm install

# Install user-app dependencies
WORKDIR /project/user-app
COPY ./user-app/package*.json ./

# RUN `npm install` instead of `npm install --production` as we need to transpile TS code
RUN npm install
WORKDIR /project/user-app/node_modules

# Copy the dependencies into a slim Node docker image
FROM registry.access.redhat.com/ubi8/nodejs-12

USER root

RUN yum -y clean all && yum repolist \
  && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && yum -y install python2 \
  && ln -s $(which python2) /usr/local/bin/python \
  && echo "Finished installing dependencies"

RUN groupadd node && useradd -r -g node node  -m -d /home/node/

# Copy the project
COPY --chown=node:node . /project

# Copy all dependencies
COPY --chown=node:node --from=0 /project/node_modules /project/node_modules
COPY --chown=node:node --from=0 /project/user-app/node_modules /project/user-app/node_modules

WORKDIR /project

# Make sure TypeScript source code is transpiled
RUN npm run build && npm run build --prefix user-app

ENV NODE_ENV production
ENV PORT 3000

USER node

CMD ["npm", "start"]
