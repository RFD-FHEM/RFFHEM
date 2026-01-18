# syntax=docker/dockerfile:1@sha256:9857836c9ee4268391bb5b09f9f157f3c91bb15821bb77969642813b0d00518d
# 
# base layer with perl and some general preparations
#
FROM ghcr.io/fhem/fhem-docker:5-bookworm AS main-app



RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        gcc\
        g++ \
        && \
    rm -rf /var/lib/apt/lists/*

COPY cpanfile /usr/src/app/devcontainer/cpanfile
    
RUN cpm install --cpanfile /usr/src/app/devcontainer/cpanfile --feature devcontainer --without-test --with-suggests --with-recommends --show-build-log-on-failure --configure-timeout=360 --workers=$(nproc) --local-lib-contained /usr/src/app/devcontainer

ENV PERL5LIB=${PERL5LIB}:/usr/src/app/devcontainer/lib/perl5


# add user
#ENV FHEM_UID=1000 \
#    FHEM_GID=1000
#ARG USERNAME=fhem

#RUN set -eux \
#    && useradd --home /usr/src/RFFHEM --shell /bin/bash --uid ${FHEM_UID} --no-user-group --non-unique -m $USERNAME \
#    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
#    && chmod 0440 /etc/sudoers.d/$USERNAME
# && /bin/bash -c '. /entry.sh && setGlobal_PIDFILE && prepareFhemUser' \

EXPOSE 8083

HEALTHCHECK NONE

WORKDIR  /usr/src/RFFHEM/