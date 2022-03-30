HCP_TPMWARE_OUT := $(HCP_OUT)/tpmware
HCP_TPMWARE_SRC := $(TOP)/ext-tpmware

$(HCP_TPMWARE_OUT): | $(HCP_OUT)
MDIRS += $(HCP_TPMWARE_OUT)

# "install" is a volume for compiled and installed submodule tools. The builder
# container mounts this as it configures submodule code to compile and install
# to this path, and inter-submodule dependencies (headers, linking, ...) also
# use this install path to find each others' stuff.
HCP_TPMWARE_INSTALL := $(HCP_IMAGE_PREFIX)tpmware
HCP_TPMWARE_INSTALL_TOUCH := $(HCP_TPMWARE_OUT)/vol.created
$(HCP_TPMWARE_INSTALL_TOUCH): | $(HCP_TPMWARE_OUT)
	$Qdocker volume create $(HCP_TPMWARE_INSTALL)
	$Qtouch $@

# The path the "install" directory is mounted to.
HCP_TPMWARE_INSTALL_DEST := /install

# TODO: make this work with a read-only mount of the submodule
# The "docker run" preamble that mounts "install" where it should go
HCP_TPMWARE_DOCKER_RUN := \
	docker run -i --rm --label $(HCP_IMAGE_PREFIX)all=1 \
	--mount type=volume,source=$(HCP_TPMWARE_INSTALL),destination=$(HCP_TPMWARE_INSTALL_DEST)

# If we declare build targets with a normal dependency on
# $(HCP_BUILDER_OUT)/built (because we need the builder image in order to build
# tpmware), then any change that updates the builder image at all will cause
# a wholesale rebuild of tpmware from first principles. If instead we
# declare it with a "|" dependency, this doesn't happen (it only requires the
# builder image to exist, it won't compare timestamps).
#
# For automation sanity, we default to the meticulous case that ensures
# software is rebuilt if the build environment changes (even if the change is
# only a timestamp). Define LAZY to define the less aggressive dependencies.
ifneq (,$(LAZY))
HCP_TPMWARE_BUILDER_DEP := | $(HCP_BUILDER_OUT)/built
else
HCP_TPMWARE_BUILDER_DEP := $(HCP_BUILDER_OUT)/built
endif

# This instantiates all the support to bootstrap, configure, compile, install,
# and clean a given codebase, named by $1, which is expected to live in
# $(HCP_TPMWARE_SRC)/$1. Any dependencies on other codebases are listed in $2,
# in which case the the configure step for $1 will depend on the install step
# for each item in $2. $3 specifies a file that is guaranteed to exist in the
# top-level directory of the codebase prior to bootstrapping, that we can copy
# user/group ownership from. Other arguments provide command lines for the
# various processing steps of the
# codebase;
# $4 = command line to bootstrap the codebase
# $5 = command line to configure the codebase
# $6 = command line to compile the codebase
# $7 = command line to install the codebase
define tpmware_add_codebase
$(eval TPMWARE_MODULES += $1)
$(eval TPMWARE_$1_RUN := $(HCP_TPMWARE_DOCKER_RUN))
$(eval TPMWARE_$1_RUN += --mount type=bind,source=$(HCP_TPMWARE_SRC)/$1,destination=/$1)
$(eval TPMWARE_$1_RUN += $(HCP_BUILDER_DNAME))
$(eval TPMWARE_$1_RUN += bash -c)
$(eval TPMWARE_$1_CHOWN += /hcp/base/chowner.sh $3 .)
$(eval TPMWARE_$1_BOOTSTRAP := cd /$1 ; $(strip $4) ; $(TPMWARE_$1_CHOWN))
$(eval TPMWARE_$1_CONFIGURE := cd /$1 ; $(strip $5) ; $(TPMWARE_$1_CHOWN))
$(eval TPMWARE_$1_COMPILE := cd /$1 ; $(strip $6) ; $(TPMWARE_$1_CHOWN))
$(eval TPMWARE_$1_INSTALL := cd /$1 ; $(strip $7) ; $(TPMWARE_$1_CHOWN))
$(HCP_TPMWARE_OUT)/$1.bootstrapped: $(HCP_TPMWARE_SRC)/$1/$3
$(HCP_TPMWARE_OUT)/$1.bootstrapped: $(HCP_TPMWARE_BUILDER_DEP)
$(HCP_TPMWARE_OUT)/$1.bootstrapped: | $(HCP_TPMWARE_INSTALL_TOUCH)
$(HCP_TPMWARE_OUT)/$1.bootstrapped:
	$Q$(TPMWARE_$1_RUN) "$(TPMWARE_$1_BOOTSTRAP)"
	$Qtouch $$@
$(HCP_TPMWARE_OUT)/$1.configured: $(HCP_TPMWARE_OUT)/$1.bootstrapped
$(foreach i,$(strip $2),
$(HCP_TPMWARE_OUT)/$1.configured: $(HCP_TPMWARE_OUT)/$i.installed
)
$(HCP_TPMWARE_OUT)/$1.configured:
	$Q$(TPMWARE_$1_RUN) "$(TPMWARE_$1_CONFIGURE)"
	$Qtouch $$@
$(HCP_TPMWARE_OUT)/$1.compiled: $(HCP_TPMWARE_OUT)/$1.configured
$(HCP_TPMWARE_OUT)/$1.compiled:
	$Q$(TPMWARE_$1_RUN) "$(TPMWARE_$1_COMPILE)"
	$Qtouch $$@
$(HCP_TPMWARE_OUT)/$1.installed: $(HCP_TPMWARE_OUT)/$1.compiled
$(HCP_TPMWARE_OUT)/$1.installed:
	$Q$(TPMWARE_$1_RUN) "$(TPMWARE_$1_INSTALL)"
	$Qtouch $$@
$(if $(HCP_TPMWARE_SUBMODULE_RESET),
$(HCP_TPMWARE_OUT)/$1.reset:
	$Q(cd $(HCP_TPMWARE_SRC)/$1 && git clean -f -d -x && git reset --hard)
	$Qrm -f $(HCP_TPMWARE_OUT)/$1.*
$(eval TPMWARE_MODULES_RESET += $(HCP_TPMWARE_OUT)/$1.reset)
)
$(if $(HCP_TPMWARE_SUBMODULE_TARGETS),
tpmware_$1: $(HCP_TPMWARE_OUT)/$1.installed
tpmware_$1_bootstrap: $(HCP_TPMWARE_OUT)/$1.bootstrapped
tpmware_$1_configure: $(HCP_TPMWARE_OUT)/$1.configured
tpmware_$1_compile: $(HCP_TPMWARE_OUT)/$1.compiled
tpmware_$1_install: $(HCP_TPMWARE_OUT)/$1.installed
$(if $(HCP_TPMWARE_SUBMODULE_RESET),
tpmware_$1_reset: $(HCP_TPMWARE_OUT)/$1.reset
)
)
endef


# Only compile-in tpm2-tss and tpm2-tools if we're not using upstream packages
ifdef HCP_TPMWARE_TPM2

############
# tpm2-tss #
############

$(eval $(call tpmware_add_codebase,tpm2-tss,,bootstrap,\
	./bootstrap,\
	./configure --disable-doxygen-doc --prefix=$(HCP_TPMWARE_INSTALL_DEST),\
	make $(HCP_TPMWARE_MAKE_PARALLEL),\
	make install,\
	make clean,\
	make uninstall))

##############
# tpm2-tools #
##############

# Bug alert: previously, setting PKG_CONFIG_PATH was enough for tpm2-tools to
# detect everything it needs. Now, it fails to find "tss2-esys>=2.4.0" and
# suggests setting TSS2_ESYS_2_3_{CFLAGS,LIBS} "to avoid the need to call
# pkg-config". Indeed, setting these works, but those same settings should have
# been picked up from the pkgconfig directory...
HACK_TPM2-TOOLS += PKG_CONFIG_PATH=$(HCP_TPMWARE_INSTALL_DEST)/lib/pkgconfig
HACK_TPM2-TOOLS += TSS2_ESYS_2_3_CFLAGS=\"-I$(HCP_TPMWARE_INSTALL_DEST) -I$(HCP_TPMWARE_INSTALL_DEST)/tss2\"
HACK_TPM2-TOOLS += TSS2_ESYS_2_3_LIBS=\"-L$(HCP_TPMWARE_INSTALL_DEST)/lib -ltss2-esys\"
$(eval $(call tpmware_add_codebase,tpm2-tools,tpm2-tss,bootstrap,\
	$(HACK_TPM2-TOOLS) ./bootstrap,\
	$(HACK_TPM2-TOOLS) ./configure --prefix=$(HCP_TPMWARE_INSTALL_DEST),\
	$(HACK_TPM2-TOOLS) make $(HCP_TPMWARE_MAKE_PARALLEL),\
	$(HACK_TPM2-TOOLS) make install,\
	$(HACK_TPM2-TOOLS) make clean,\
	$(HACK_TPM2-TOOLS) make uninstall))

endif # HCP_TPMWARE_TPM2

###########
# libtpms #
###########

$(eval $(call tpmware_add_codebase,libtpms,,autogen.sh,\
	NOCONFIGURE=1 ./autogen.sh,\
	./configure --with-openssl --with-tpm2 --prefix=$(HCP_TPMWARE_INSTALL_DEST),\
	make $(HCP_TPMWARE_MAKE_PARALLEL),\
	make install,\
	make clean,\
	make uninstall))

#########
# swtpm #
#########

$(eval $(call tpmware_add_codebase,swtpm,libtpms,autogen.sh,\
	NOCONFIGURE=1 ./autogen.sh,\
	LIBTPMS_LIBS='-L$(HCP_TPMWARE_INSTALL_DEST)/lib -ltpms' \
	LIBTPMS_CFLAGS='-I$(HCP_TPMWARE_INSTALL_DEST)/include' \
	./configure --with-openssl --with-tpm2 --prefix=$(HCP_TPMWARE_INSTALL_DEST),\
	make $(HCP_TPMWARE_MAKE_PARALLEL),\
	make install,\
	make clean,\
	make uninstall))

##################
# install.tar.gz #
##################

HCP_TPMWARE_INSTALL_RUN := $(HCP_TPMWARE_DOCKER_RUN) \
	--mount type=bind,source=$(HCP_TPMWARE_OUT),destination=/put_it_here \
	$(HCP_BUILDER_DNAME) \
	bash -c

TGZ_CMD := cd /put_it_here ;
TGZ_CMD += tar zcf install.tar.gz $(HCP_TPMWARE_INSTALL_DEST) ;
TGZ_CMD += /hcp/base/chowner.sh swtpm.installed install.tar.gz

$(HCP_TPMWARE_OUT)/install.tar.gz: $(foreach i,$(TPMWARE_MODULES),$(HCP_TPMWARE_OUT)/$i.installed)
$(HCP_TPMWARE_OUT)/install.tar.gz:
	$Q$(HCP_TPMWARE_INSTALL_RUN) "$(TGZ_CMD)"

# A wrapper target to build the tpmware
tpmware: $(HCP_TPMWARE_OUT)/install.tar.gz
ALL += tpmware

# Cleanup
ifneq (,$(wildcard $(HCP_TPMWARE_OUT)))
clean_tpmware: $(TPMWARE_MODULES_RESET)
	$Qrm -f $(HCP_TPMWARE_OUT)/install.tar.gz
ifneq (,$(wildcard $(HCP_TPMWARE_INSTALL_TOUCH)))
	$Qdocker volume rm $(HCP_TPMWARE_INSTALL)
	$Qrm $(HCP_TPMWARE_INSTALL_TOUCH)
endif
	$Qrm -rf $(HCP_TPMWARE_OUT)
# Cleanup ordering
clean_builder: clean_tpmware
endif
