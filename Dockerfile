# Copyright 2024 Trustap. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# We use Alpine Linux to keep the size of the image small. However, this can
# have unexpected consequences at runtime - for instance, `ca-certificates` that
# usually come preinstalled with Debian images need to be installed manually.
# Furthermore, features that depend on certain executables will need to ensure
# that these are available in the Alpine Linux environment, and that these
# behave the same as the versions that have been tested against. For this
# reason, local tests should be run against the "run" Docker image rather than
# the "build" Docker image.
FROM alpine:3.20.3

WORKDIR /app

RUN \
    apk add ca-certificates \
	&& wget \
		--output-document /tmp/envsubst \
		https://github.com/a8m/envsubst/releases/download/v1.1.0/envsubst-Linux-x86_64 \
	&& install \
		-m 0755 \
		/tmp/envsubst \
		/usr/local/bin \
	&& rm /tmp/envsubst

COPY \
    api.sample.yaml \
    check_env_config.sh \
    docker_entrypoint.sh \
    service_template \
    /app/

RUN \
    touch config.yaml \
    && chown \
        1001:1001 \
        config.yaml

USER 1001

EXPOSE 80

ENTRYPOINT ["sh", "docker_entrypoint.sh", ":80"]
