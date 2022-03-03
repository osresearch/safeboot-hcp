# Some templates and other routines to reduce duplication
include $(HCP_SRC)/preproc.Makefile

# A "base platform" Docker image is created, and used as a basis for deriving
# two kinds of images;
# - a "builder" container image, containing tool-chains and other extras to
#   facilitate the building of submodules.
# - application container images, providing the different services, side-cars,
#   and utilities that constitue HCP.
include $(HCP_SRC)/base/Makefile

# A "builder" docker image is created that can host building of submodule code
# (rather than building directly in the host environment, which can be
# undesirable, unreliable, or impossible for many reasons).
include $(HCP_SRC)/builder/Makefile

# Compile external tpm tools from source (using "builder"), resulting in
# install.tar.gz, literally a tarball of a root-level installation ("/install")
# of the tools.
include $(HCP_SRC)/ext-tpmware.Makefile

# Produce a tarball of tools installed from safeboot
include $(HCP_SRC)/ext-safeboot.Makefile

# Produce HCP applications (container images)
include $(HCP_SRC)/apps/Makefile

# Produce usable (but test, non-production) credentials
include $(HCP_SRC)/creds.Makefile
