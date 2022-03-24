# Build stage
FROM registry.access.redhat.com/ubi8/nodejs-16:latest AS build

## Set current working directory
WORKDIR /opt/app-root/src

## Copy the package.json for audit
COPY package*.json ./

## Copy the dockerfile's context's community server files
COPY . .

## Install and build the Solid community server (prepare script cannot run in wd)
RUN npm ci --unsafe-perm && npm run build

# Runtime stage
FROM registry.access.redhat.com/ubi8/nodejs-16-minimal:latest AS runtime

## Add contact informations for questions about the container
LABEL maintainer="Solid Community Server Docker Image Maintainer <matthieubosquet@gmail.com>"

## Container config & data dir for volume sharing
## Defaults to filestorage with /data directory (passed through CMD below)
RUN mkdir /opt/app-root/data

## Set current directory
WORKDIR /opt/app-root/src

## Copy runtime files from build stage
COPY --from=build /opt/app-root/src/package.json .
COPY --from=build /opt/app-root/src/bin ./bin
COPY --from=build /opt/app-root/src/config ./config
COPY --from=build /opt/app-root/src/dist ./dist
COPY --from=build /opt/app-root/src/node_modules ./node_modules
COPY --from=build /opt/app-root/src/templates ./templates

## Configure permissions for App Directories & Run Container as Non-Root User
RUN chgrp -R 0 /opt/app-root/data && \
    chmod -R g=u /opt/app-root/data

RUN chown -R 1001:0 /opt/app-root/data    
USER 1001

## Informs Docker that the container listens on the specified network port at runtime
EXPOSE 3000

## Set command run by the container
ENTRYPOINT [ "node", "bin/server.js" ]

## By default run in filemode (overriden if passing alternative arguments)
CMD [ "-c", "config/file.json", "-f", "/opt/app-root/data" ]
