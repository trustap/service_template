project := 'service_template'
img := 'trustap' / project
build_conf_dir := 'configs/build'
tgt_dir := 'target'
tgt_artfs_dir := tgt_dir / 'artfs'
tgt := tgt_artfs_dir / project
tgt_tmp_dir := tgt_dir / 'tmp'
tgt_img_ctx_dir := tgt_tmp_dir / 'img_ctx'

# We list the sub-packages to be tested explicitly (instead of including all
# files) so that we can skip source files that make be in `tgt_dir`.
src_dirs := 'cmd pkg'

# List available recipes.
default:
    just --list

# Start the default command.
run conf='configs/api.yaml' addr='0.0.0.0:8080':
    make '{{tgt}}'
    '{{tgt}}' \
        '{{conf}}' \
        '{{addr}}'

# Start the default container.
run_cont addr='0.0.0.0:8080': build_img
    test -f 'configs/env'
    docker run \
        --rm \
        --interactive \
        --tty \
        --publish '{{addr}}:80' \
        --env-file='configs/env' \
        '{{img}}:latest'

# These checks are ordered in terms of estimated runtime, from quickest to
# slowest, so that failures should be found as quickly as possible.
#
# Run all tests.
check: && check_style check_lint
    make '{{tgt}}'

# Run style checks.
check_style: check_go_style

# Run style checks for Go files.
check_go_style:
    @# `gofmt` returns 0 even if formatting issues were found. However, it only
    @# produces output if issues were found so we fail the check if any output
    @# was produced.
    @#
    @# We check the formatting with `gofmt` after `gofumpt` and `goimports` to
    @# avoid drift between the different formatters; `gofmt` is the canonical
    @# representation.
    ! (gofumpt -d {{src_dirs}} | grep '')
    ! (goimports -d {{src_dirs}} | grep '')
    ! (gofmt -s -d {{src_dirs}} | grep '')
    comment_style '{{build_conf_dir}}/comment_style.yaml'

# Check for semantic issues in Go files.
check_lint:
    @# `revive` is supported by `golangci-lint`, but we run `revive` directly
    @# here because it's unclear how to disable specific `revive` rules via the
    @# `golangci-lint` configuration.
    @#
    @# TODO There is an overlap between some linters that `golangci-lint`
    @# provides and `revive`. `revive` should be used to replace these where
    @# possible, for consistency, and because `revive` generally runs faster
    @# than `golangci-lint`.
    revive \
        -config='{{build_conf_dir}}/revive.toml' \
        -formatter=plain \
        cmd/... \
        pkg/...
    golangci-lint run \
        --config='{{build_conf_dir}}/golangci.yaml' \
        cmd/... \
        pkg/...

# Format source files.
fmt:
    gofumpt -w .

# Build the 'run' image for this project.
build_img version='latest':
    make target/artfs/service_template
    rm -rf '{{tgt_img_ctx_dir}}'
    make \
        '{{tgt}}' \
        '{{tgt_img_ctx_dir}}'
    cp \
        configs/api.sample.yaml \
        scripts/check_env_config.sh \
        scripts/docker_entrypoint.sh \
        '{{tgt_artfs_dir}}'/service_template \
        '{{tgt_img_ctx_dir}}'
    bash scripts/docker_rbuild.sh \
        '{{img}}' \
        '{{version}}' \
        --file='Dockerfile' \
        '{{tgt_img_ctx_dir}}'
