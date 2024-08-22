tgt_dir:=target
tgt_artfs_dir:=$(tgt_dir)/artfs
pkg:=github.com/trustap/template

# We list the sub-packages to be tested explicitly (instead of including all
# files) so that we can skip source files that make be in `tgt_dir`.
src_dirs:=cmd pkg

deps:=$(shell find $(src_dirs) -name '*.go' -type f)

# Build all artefacts.
.PHONY: artfs
artfs: \
	$(tgt_artfs_dir)/template

# We disable cgo when building so that these executables can be run in
# environments outside those that they were built in. For example, builds are
# generally performed in a Debian environment but executables will ideally run
# in minimal Alpine environments. Note that this can result in slower builds
# (<https://stackoverflow.com/a/47715985>).
$(tgt_artfs_dir)/%: $(deps) | $(tgt_artfs_dir)
	( \
		cd cmd/$(notdir $@) \
		&& go get -v \
		&& CGO_ENABLED=0 go build \
			-o '../../$@' \
	)

$(tgt_artfs_dir): | $(tgt_dir)
	mkdir '$@'

$(tgt_dir):
	mkdir '$@'
