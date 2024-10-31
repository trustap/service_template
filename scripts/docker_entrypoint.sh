# Copyright 2024 Trustap. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0` writes a new `config.yaml` using values from the environment and starts
# the service listening on port 80.
#
# This command fails if any required environment variables are blank.

set -o errexit
set -o pipefail

if [ $# -ne 1 ] ; then
    echo "usage: $0 <listen-addr>" >&2
    exit 1
fi

listen_addr="$1"

optional='
    GREETING_EXTRA
'

# This removes the empty lines at the start and end of `$optional`.
optional_trimmed=$(
    echo "$optional" \
        | sed '1 d' \
        | sed '$ d'
)

sh check_env_config.sh \
    api.sample.yaml \
    "$optional_trimmed"

envsubst < api.sample.yaml > config.yaml

./service_template \
    config.yaml \
    "$listen_addr"
