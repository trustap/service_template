tgt_dir := "target"

# We list the sub-packages to be tested explicitly (instead of including all
# files) so that we can skip source files that make be in `tgt_dir`.
src_dirs := "cmd"

# List available recipes.
default:
    just --list

# Start the default command.
run:
    make target/artfs/template
    target/artfs/template
