# All Docker objects created by this workflow will be prefixed with this string
# in order to allow multiple independent environments to be built and tested on
# the same host system. (E.g. this can include a "/" separator for user
# repositories.)
HCP_DSPACE ?= hcp_

# Specifies the tag suffix to be used for all Docker container images we create
# and use. When this is empty, Docker creates images with a default tag
# (usually "latest"), but with this setting lets you override that.  (E.g.
# "debug", "production", "cloud", "$(commit_id)", ...) In this workflow, a
# build of "whatever" would produce a container image called;
#     $(HCP_DSPACE)whatever:$(HCP_DTAG)
HCP_DTAG ?= devel
# Now prefix the ":" once and for all;
ifdef HCP_DTAG
HCP_DTAG := :$(HCP_DTAG)
endif

# Specify the underlying (debian-based) docker image to use as the system
# environment for all operations.
# - This will affect the versions of numerous system packages that get
#   installed and used, which may affect the compatibility of any resulting
#   artifacts.
# - This gets used directly in the FROM command of the generated Dockerfile, so
#   "Docker semantics" apply here (in terms of whether it is pulling an image
#   or a Dockerfile, whether it pulls a named image from a default repository
#   or one that is specified explicitly, etc).
# - This baseline container image also gets used as a "utility" container, used
#   particularly when needing to run cleanup shell-commands and "any image will
#   do". NB: this should be kept synchronized with
#   hcp/run/direct.mk::HCP_RUN_UTIL_IMAGE
HCP_BASE ?= debian:bullseye-slim
#HCP_BASE ?= internal.dockerhub.mycompany.com/library/debian:buster-slim

# Define this to inhibit all dependency on top-level Makefiles and this
# settings file.
HCP_RELAX := 1

# If defined, the "1apt-source" layer in hcp/base will be used, allowing apt to
# use an alternative source of debian packages, trust different package signing
# keys, etc.
# See hcp/base/Makefile for details.
#HCP_1APT_ENABLE := 1

# If defined, the "3add-cacerts" layer in hcp/base will be injected, allow
# host-side trust roots (CA certificates) to be installed.
# See hcp/base/Makefile for details.
#HCP_3ADD_CACERTS_ENABLE := 1
#HCP_3ADD_CACERTS_PATH := /opt/my-company-ca-certificates

# If defined, the "4platform" layer will add a "RUN apt-get install -y [...]"
# line to its Dockerfile using these arguments. This provides for "make
# yourself at home" stuff to be added to all the subsequent HCP-produced
# containers.
HCP_4PLATFORM_XTRA ?= vim

# If defined, the "4platform" layer in hcp/base will not install "tpm2-tools"
# from Debian package sources, instead the tpm2-tss and tpm2-tools submodules
# will be configured, compiled, and installed by the ext-tpmware submodules.
HCP_4PLATFORM_NO_TPM2 := 1

# As per above. DO NOT MODIFY this unless you know what you're doing.
HCP_TPMWARE_TPM2 := $(HCP_4PLATFORM_NO_TPM2)

# If defined, the "2apt-usable" layer in hcp/base will tweak the apt
# configuration to use the given URL as a (caching) proxy for downloading deb
# packages. It will also set the "Queue-Mode" to "access", which essentially
# serializes the pulling of packages. (I tried a couple of different
# purpose-built containers for proxying and all would glitch sporadically when
# apt unleashed its parallel goodness upon them. That instability may be in
# docker networking itself. Serializing slows the downloading noticably, but
# the whole point is that once the cache has a copy of everything, package
# downloads go considerably faster, and the lack of parallelism goes largely
# unnoticed.)
#
# docker run --name apt-cacher-ng --init -d --restart=always \
#  --publish 3142:3142 \
#  --volume /srv/docker/apt-cacher-ng:/var/cache/apt-cacher-ng \
#  sameersbn/apt-cacher-ng:3.3-20200524
#
#HCP_APT_PROXY := http://172.17.0.1:3142

# These flags get passed to "make" when compiling submodules. "-j" on its own
# allows make to spawn arbitrarily many processes at once, whereas "-j 4" caps
# the parallelism to 4.
HCP_BUILDER_MAKE_PARALLEL := -j 16

# If the following is enabled, the submodule-building support will assume it
# "owns" the submodules. I.e. it will not only autoconf, configure, compile,
# and install the submodules, it will "clean" them back to pristine state. This
# includes running "git clean -f -d -x" (to get rid of all non-version
# controlled files), and running "git reset --hard" (restoring missing files
# and resetting existing files to their versioned state). Great for CI and
# other automation, but not great if you are _hacking on the submodule code and
# don't want all your work vanishing in smoke_!! We default to the latter by
# commenting this setting out, to avoid harm though reducing purity. Enable it
# if you prefer having the git-clean and git-reset steps.
#HCP_TPMWARE_SUBMODULE_RESET := 1

# Unless you are hacking on individual tpmware submodules (libtpms, swtpm,
# tpm2-tss, tpm2-tools), it probably suffices for you have a single "tpmware"
# make target that bootstraps, configures, compiles, and installs all the
# submodules by dependency. Having a single target leaves tab-completion of
# make targets simpler/cleaner. On the other hand, enable the following if you
# want fine-grained targets.
#HCP_TPMWARE_SUBMODULE_TARGETS := 1
