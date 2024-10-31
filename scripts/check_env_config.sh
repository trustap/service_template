# Copyright 2024 Trustap. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.
#
# `$0 <config-file> <optional-names>` searches `config-file` for all environment
# variables (of the form `${...}` and fails if there is any environment variable
# found that doesn't have a value, ignoring variable names in `optional-names`.
#
# `optional-names` should be a list of variable names, with one name per line.

set -o errexit
set -o pipefail

if [ $# -ne 2 ] ; then
    echo "usage: $0 <config-file> <optional-names>" >&2
    exit 1
fi

config_file="$1"
optional_names="$2"

# `remove_lines` takes a string of words (one on each line) and removes all
# instances of those from STDIN.
remove_lines() {
    if [ $# -ne 1 ] ; then
        echo "usage: remove_lines <lines>" >&2
        exit 1
    fi

    if [ -z "$1" ] ; then
        cat -
        exit 0
    fi

    grep_args=$(echo "$1" | sed 's/^/-e /')
    grep -v $grep_args
}

vars=$(grep '\${.*}' "$config_file" || echo '')
if [ -z "$vars" ] ; then
    exit 0
fi

# This pipe command finds all environment variable substitutions in the config
# file and strips everything but the variable names.
required=$(
    echo "$vars" \
        | sed 's/.*\${\([^}]*\)}.*/\1/g' \
        | remove_lines "$optional_names"
)

exit_code=0
for name in $required; do
    # We use `2>&1` instead of `&>` because the latter is specific to `bash`,
    # but we will run this script in environments that only have `sh`.
    printenv "$name" \
        >/dev/null \
        2>&1 \
        || {
            echo "no value passed for '$name'" >&2
            exit_code=1
        }
done

exit "$exit_code"
