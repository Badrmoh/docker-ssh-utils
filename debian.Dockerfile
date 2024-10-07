# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

LABEL MAINTAINER=engbadr@outlook.com

ENV DUID=1001 \
    DGID=1001 \
    DUSER="ssh-user" \
    DGROUP="ssh-user" \
    DHOME="/home/ssh-user" \
    SSH_PORT=2222 \
    SSHD_ENABLED="true" \
    SSH_AGENT_ENABLED="false" \
    SSH_ADD_WATCHER_ENABLED="false" \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    S6_STAGE2_HOOK="/init-hook" \
    S6_OVERLAY_VERSION="3.2.0.0"

RUN apt update && \
    apt install -y \
      xz-utils \
      tzdata locales nano \
      openssh-server \
      gnupg \
      pass \
      inotify-tools

# Copy S6 configurations
COPY --chmod=755 root/ /

# Create SSH user
RUN groupadd -g ${DUID} ${DGROUP} \
    && useradd -l \
      -m -d ${DHOME} \
      -s /bin/bash \
      -u ${DUID} \
      -g ${DGROUP} \
      ${DUSER} 

EXPOSE ${SSH_PORT:-2222}

# if openssh server is disabled, healthcheck will always fail
HEALTHCHECK --start-period=10s \
            --start-interval=10s \
            --interval=60s \
            CMD \
            nc -z localhost ${SSH_PORT:-2222}

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm -f /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-x86_64.tar.xz

ENTRYPOINT ["/init"]
