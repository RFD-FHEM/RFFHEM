# syntax=docker/dockerfile:1@sha256:9857836c9ee4268391bb5b09f9f157f3c91bb15821bb77969642813b0d00518d
# 
# base layer with perl and some general preparations
#
FROM ghcr.io/fhem/fhem-docker:5.2.7-bookworm AS main-app



RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        gcc\
        g++ \
        subversion \
        && \
        rm -rf /var/lib/apt/lists/*

COPY cpanfile /usr/src/app/devcontainer/cpanfile
    
RUN cpm install --cpanfile /usr/src/app/devcontainer/cpanfile --feature devcontainer --without-test --with-suggests --with-recommends --show-build-log-on-failure --configure-timeout=360 --workers=$(nproc) --local-lib-contained /usr/src/app/devcontainer

ENV PERL5LIB=${PERL5LIB}:/usr/src/app/devcontainer/lib/perl5

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

RUN set -eux; \
    groupadd --gid "${USER_GID}" "${USERNAME}"; \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}"; \
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

RUN set -eux; \
    mkdir -p "/home/${USERNAME}/.codex"; \
    chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.codex"

EXPOSE 8083

HEALTHCHECK NONE

WORKDIR  /workspace/RFFHEM/
