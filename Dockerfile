FROM alpine:latest AS build

ARG ELEMENTUM_VERSION="0.1.110"
ARG ELEMENTUM_ARCH="linux_x64"
ARG ADDON_NAME="plugin.video.elementum"
ARG ELEMENTUM_URL="https://github.com/elgatito/${ADDON_NAME}/releases/download/v${ELEMENTUM_VERSION}/${ADDON_NAME}-${ELEMENTUM_VERSION}.${ELEMENTUM_ARCH}.zip"

RUN wget "${ELEMENTUM_URL}" -O "/tmp/${ADDON_NAME}.zip" && \
    unzip "/tmp/${ADDON_NAME}.zip"

FROM ubuntu:latest

ARG ELEMENTUM_ARCH="linux_x64"
ARG ADDON_NAME="plugin.video.elementum"

RUN apt update && \
    apt install ca-certificates netcat-openbsd -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

USER ubuntu
WORKDIR /home/ubuntu

COPY --from=build --chown=ubuntu:ubuntu /${ADDON_NAME} ${ADDON_NAME}

RUN mkdir elementum_data/ elementum_data/elementum_addon_data/ elementum_data/elementum_torrents/ elementum_data/elementum_library/
VOLUME /home/ubuntu/elementum_data/
RUN mkdir elementum_downloads/
VOLUME /home/ubuntu/elementum_downloads/

COPY --chmod=755 <<EOF /usr/local/bin/docker-entrypoint.sh
#!/bin/sh
set -o errexit
set -o nounset

exec /home/ubuntu/${ADDON_NAME}/resources/bin/${ELEMENTUM_ARCH}/elementum \\
    -addonPath=/home/ubuntu/${ADDON_NAME}/ \\
    -tempPath=/tmp/elementum/ \\
    -profilePath=/home/ubuntu/elementum_data/elementum_addon_data/ \\
    -torrentsPath=/home/ubuntu/elementum_data/elementum_torrents/ \\
    -libraryPath=/home/ubuntu/elementum_data/elementum_library/ \\
    -logPath=/home/ubuntu/elementum_data/elementum.log \\
    -downloadsPath=/home/ubuntu/elementum_downloads/ \\
    -disableParentProcessWatcher \\
    "\$@"
EOF
ENTRYPOINT ["docker-entrypoint.sh"]
