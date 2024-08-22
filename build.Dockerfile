# Copyright 2024 Trustap. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

FROM golang:1.22.5-bullseye

ENV GOPRIVATE=github.com/trustap/*

# We create a user with the same user ID and group ID as the local user so that
# files will be created on the local filesystem with the correct permissions
# (<https://jtreminio.com/blog/running-docker-containers-as-current-host-user>).
#
# The user is created in the image in order to allow `git clone` to work with
# SSH, which fails if the user ID of the active user doesn't exist locally
# within the container (which can be the case when using
# `--user=$(id --user):$(id --group)` with `docker run`).
ARG USER_ID
ARG GROUP_ID

# We create the `/.docker` directory to store user configuration information
# when running as a non-`root` user that doesn't have a home directory, which is
# used by later versions of the Docker client.
RUN \
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        https://get.docker.com \
    | VERSION=20.10.8 sh \
    && mkdir /.docker \
    && chmod 0777 /.docker

RUN \
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        'https://github.com/a8m/envsubst/releases/download/v1.1.0/envsubst-Linux-x86_64' \
        > /usr/local/bin/envsubst \
    && chmod \
        +x \
        /usr/local/bin/envsubst

RUN \
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        'https://just.systems/install.sh' \
    | bash \
        -s \
        -- \
        --tag 1.14.0 \
        --to /usr/local/bin

RUN \
    set -o errexit ; \
    if \
        [ -z "$USER_ID" ] || [ $USER_ID -eq 0 ] \
            || [ -z "$GROUP_ID" ] || [ $GROUP_ID -eq 0 ] ; \
    then \
        echo "non-root 'USER_ID' and 'GROUP_ID' must be provided" ; \
        false ; \
    fi ; \
    groupadd \
        --gid "$GROUP_ID" \
        hostuser \
        ; \
    useradd \
        --no-log-init \
        --uid "$USER_ID" \
        --gid "$GROUP_ID" \
        --create-home \
        hostuser \
        ;

USER hostuser

# The following forces Git to use SSH when fetching private repositories. See
# <https://stackoverflow.com/a/27501039> for more information.
RUN \
    mkdir \
        /home/hostuser/.ssh \
    && git config \
        --global \
        url.'git@github.com:trustap/'.insteadOf 'https://github.com/trustap/'
