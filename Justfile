build_conf_dir := "configs/build"
tgt_dir := "target"

# We list the sub-packages to be tested explicitly (instead of including all
# files) so that we can skip source files that make be in `tgt_dir`.
src_dirs := "cmd pkg"

# List available recipes.
default:
    just --list

# Start the default command.
run addr='0.0.0.0:8080':
    make target/artfs/service_template
    target/artfs/service_template '{{addr}}'

# These checks are ordered in terms of estimated runtime, from quickest to
# slowest, so that failures should be found as quickly as possible.
#
# Run all tests.
check: && check_style check_lint
    make target/artfs/service_template

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
