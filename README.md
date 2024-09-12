README
=====

About
------

This project defines a template for backend projects at Trustap.

Development
-----------

### Building

#### With Docker

If Docker is installed then the artefacts can be built as follows:

    bash scripts/with_build_env.sh make

#### Without Docker

The instructions in `build.Dockerfile` can be followed to prepare your local
environment for building the project. With the local environment set up, the
project can be built locally by running `make`.

### Running

The default executable for the project can be built and run from the build
environment using `just run`.

#### Outputs

Multiple directories are generated to the `target` directory.

* `artfs` contains build artefacts that can be reused by other projects. For
  example, a library binary or command executable, which can be added to a
  Docker image. These are generally copied to an artefact server to represent a
  given version of the codebase.
* `gen` contains artefacts that are used to build or test other artefacts, but
  which themselves aren't reusable. For example, this directory may contain a
  mock server for integration testing, or a code generator needed to create
  source files for the final build. These shouldn't be copied to an artefact
  server. It's safe to delete this directory, though generally the artefacts in
  this directory are useful to keep in order to speed up future builds.
* `tmp` contains temporary data that may be used by some build processes. For
  example, tests may require a directory where test data or reports can be
  written. These will generally be deleted and rebuilt each time the associated
  build process runs, so they can be deleted without problems.

### Capabilities

By default this project is set up with a few capabilities to allow it to be used
in enterprise settings:

* Nested Docker: The default `build.Dockerfile` installs Docker, and the default
  build environment (using `scripts/with_build_env.sh`) mounts the local Docker
  socket into the container to allow Docker to be run from inside the build
  environment. See <https://seankelleher.ie/posts/with_build_env/> for more
  information on this approach.
* Private shared repositories: Local SSH keys and "known hosts" files can be
  mounted into the default build environment to allow access to private
  repositories hosted on public repository hosting services like GitHub.

### Project Layout

This project is mainly laid out according to
<https://github.com/golang-standards/project-layout>, and conforms to the
standards laid out in
<https://trustap.atlassian.net/wiki/spaces/ENGINEERING/pages/427950081/Trustap+Code+Style>.
