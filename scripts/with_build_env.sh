# Copyright 2024 Trustap. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 [--dev] [--fwd-ssh-agent] [--known-hosts <known-hosts-file>] [--uid <uid>]
# [--gid <gid>]` runs a command in the build environment.
#
# The `dev` argument runs the build environment in interactive mode with a new
# TTY and using the host network.
#
# The `fwd-ssh-agent` flag makes the local SSH agent at `$SSH_AUTH_SOCK`
# available within the build environment.
#
# The `known-hosts` argument makes the specified `known-hosts-file` available
# within the build environment. Note that the `known-hosts-file` path must not
# contain spaces.
#
# The `uid` and `gid` arguments run the command using the given user ID and
# group ID.

set -o errexit

# We run the build as the local user (`id --user` and `id --group`) by default
# so that files will be created on the local filesystem with the correct
# permissions.
uid="$(id --user)"
gid="$(id --group)"
docker_flags=''
while true ; do
    case "$1" in
        --dev)
            docker_flags="$docker_flags --interactive --tty --network=host"
            shift 1
            ;;
        --fwd-ssh-agent)
            docker_flags="$docker_flags --volume=$SSH_AUTH_SOCK:/ssh_agent --env=SSH_AUTH_SOCK=/ssh_agent"
            shift 1
            ;;
        --known-hosts)
            docker_flags="$docker_flags --volume=$2:/home/hostuser/.ssh/known_hosts:ro"
            shift 2
            ;;
        --uid)
            uid="$2"
            shift 2
            ;;
        --gid)
            gid="$2"
            shift 2
            ;;
        --docker-network)
            docker_flags="
                $docker_flags
                --network=$2
            "
            shift 2
            ;;
        --docker-flag)
            docker_flags="
                $docker_flags
                $2
            "
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

org_name='trustap'
proj_name='service_template'
img_name="$org_name/$proj_name.build"

bash scripts/docker_rbuild.sh \
    "$img_name" \
    latest \
    --build-arg=USER_ID="$uid" \
    --build-arg=GROUP_ID="$gid" \
    - \
    < build.Dockerfile

# We use named volumes to keep the Go caches between builds. We make them
# writable by anyone because we run the build as the local user (`id --user` and
# `id --group`), and the volumes are owned by root by default.
#
# We recursively set the permissions because `/go/pkg/mod` is initially created
# and populated by `root` when the image is built (e.g. by using `go get` to
# install some initial tools).
docker run \
    --rm \
    --user=root \
    --volume="${org_name}.${proj_name}.tmp_cache":/tmp/cache \
    --volume="${org_name}.${proj_name}.mod_cache":/go/pkg \
    "$img_name:latest" \
    chmod \
        --recursive \
        0777 \
        /tmp/cache \
        /go/pkg

# See `scripts/docker_hostpath.sh` for details on `DOCKER_MOUNT_SRC` and
# `DOCKER_MOUNT_TGT`.
DOCKER_MOUNT_SRC="$(bash scripts/docker_hostpath.sh $(pwd))"
DOCKER_MOUNT_TGT=/go/src/github.com/trustap/rest_api

# The group ID for the `docker` group on the host can be different from
# the `docker` group created inside the image when installing `docker`.
# If they're different, then a non-root user in the container can't access
# the host's `/var/run/docker.sock` socket because they're not in the
# correct group. For this reason, we get the exact group ID of the `docker`
# group on the host and explicitly add the user to this group ID so that
# they can access the socket.
host_docker_group_id=$(
    getent group \
        docker \
        | cut \
            --delimiter=: \
            --fields=3
)

# We use `--init` so that the signals sent by commands like `docker stop` are
# handled as expected, which can be useful when cancelling worflows running in
# build pipelines and allow for faster termination of such processes.
#
# `XDG_CACHE_HOME` is used by Go to determine where the build cache should be.
docker run \
    $docker_flags \
    --rm \
    --init \
    --user="$uid":"$gid" \
    --env=XDG_CACHE_HOME=/tmp/cache \
    --volume="${org_name}.${proj_name}.tmp_cache":/tmp/cache \
    --volume="${org_name}.${proj_name}.mod_cache":/go/pkg \
    --volume="$DOCKER_MOUNT_SRC":"$DOCKER_MOUNT_TGT" \
    --workdir="$DOCKER_MOUNT_TGT" \
    --group-add="$host_docker_group_id" \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --env=DOCKER_MOUNT_SRC="$DOCKER_MOUNT_SRC" \
    --env=DOCKER_MOUNT_TGT="$DOCKER_MOUNT_TGT" \
    "$img_name:latest" \
    "$@"
