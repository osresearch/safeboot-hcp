HCP_SUBMODULES_OUT := $(HCP_OUT)/submodules

$(HCP_SUBMODULES_OUT): | $(HCP_OUT)
MDIRS += $(HCP_SUBMODULES_OUT)

# "install" is a persistent directory for compiled and installed submodule
# tools. The builder container mounts this as it configures submodule code to
# compile and install to this path, and inter-submodule dependencies (headers,
# linking, ...) also use this install path to find each others' stuff.
HCP_SUBMODULES_INSTALL := $(HCP_SUBMODULES_OUT)/install
$(HCP_SUBMODULES_INSTALL): | $(HCP_SUBMODULES_OUT)
MDIRS += $(HCP_SUBMODULES_INSTALL)

# The path the "install" directory is mounted to.
HCP_SUBMODULES_INSTALL_DEST := /install

# The "docker run" preamble that mounts "install" where it should go
HCP_SUBMODULES_DOCKER_RUN := \
	docker run -i --rm --label $(SAFEBOOT_HCP_DSPACE)all=1 \
	-v $(HCP_SUBMODULES_INSTALL):$(HCP_SUBMODULES_INSTALL_DEST)

# If we declare build targets with a normal dependency on
# $(HCP_BUILDER_OUT)/built (because we need the builder image in order to build
# submodules), then any change that updates the builder image at all will cause
# a wholesale rebuild of submodules from first principles. If instead we
# declare it with a "|" dependency, this doesn't happen (it only requires the
# builder image to exist, it won't compare timestamps).
#
# For automation sanity, we default to the meticulous case that ensures
# software is rebuilt if the build environment changes (even if the change is
# only a timestamp). Define LAZY to define the less aggressive dependencies.
ifneq (,$(LAZY))
HCP_SUBMODULES_BUILDER_DEP := | $(HCP_BUILDER_OUT)/built
else
HCP_SUBMODULES_BUILDER_DEP := $(HCP_BUILDER_OUT)/built
endif


# Only compile-in tpm2-tss and tpm2-tools if we're not using upstream packages
ifdef SAFEBOOT_HCP_SUBMODULES_TPM2

############
# tpm2-tss #
############

HCP_SUBMODULES_TPM2-TSS_RUN := $(HCP_SUBMODULES_DOCKER_RUN) \
	-v $(TOP)/tpm2-tss:/tpm2-tss \
	$(HCP_BUILDER_DNAME) \
	bash -c

$(HCP_SUBMODULES_OUT)/tpm2-tss.autogened: tpm2-tss/bootstrap
$(HCP_SUBMODULES_OUT)/tpm2-tss.autogened: $(HCP_SUBMODULES_BUILDER_DEP)
$(HCP_SUBMODULES_OUT)/tpm2-tss.autogened: | $(HCP_SUBMODULES_INSTALL)
$(HCP_SUBMODULES_OUT)/tpm2-tss.autogened:
	$Q$(HCP_SUBMODULES_TPM2-TSS_RUN) "cd /tpm2-tss ; ./bootstrap"
	$Qtouch $@

CMD_TPM2-TSS_CFG := cd /tpm2-tss ;
CMD_TPM2-TSS_CFG += ./configure --disable-doxygen-doc
CMD_TPM2-TSS_CFG += --prefix=$(HCP_SUBMODULES_INSTALL_DEST)
$(HCP_SUBMODULES_OUT)/tpm2-tss.configured: $(HCP_SUBMODULES_OUT)/tpm2-tss.autogened
$(HCP_SUBMODULES_OUT)/tpm2-tss.configured:
	$Q$(HCP_SUBMODULES_TPM2-TSS_RUN) "$(CMD_TPM2-TSS_CFG)"
	$Qtouch $@

CMD_TPM2-TSS_COMPILE := cd /tpm2-tss ; make $(SAFEBOOT_HCP_SUBMODULES_MAKE_PARALLEL)
$(HCP_SUBMODULES_OUT)/tpm2-tss.compiled: $(HCP_SUBMODULES_OUT)/tpm2-tss.configured
$(HCP_SUBMODULES_OUT)/tpm2-tss.compiled:
	$Q$(HCP_SUBMODULES_TPM2-TSS_RUN) "$(CMD_TPM2-TSS_COMPILE)"
	$Qtouch $@

$(HCP_SUBMODULES_OUT)/tpm2-tss.installed: $(HCP_SUBMODULES_OUT)/tpm2-tss.compiled
$(HCP_SUBMODULES_OUT)/tpm2-tss.installed:
	$Q$(HCP_SUBMODULES_TPM2-TSS_RUN) "cd /tpm2-tss ; make install"
	$Qtouch $@

##############
# tpm2-tools #
##############

HCP_SUBMODULES_TPM2-TOOLS_RUN := $(HCP_SUBMODULES_DOCKER_RUN) \
	-v $(TOP)/tpm2-tools:/tpm2-tools \
	$(HCP_BUILDER_DNAME) \
	bash -c

$(HCP_SUBMODULES_OUT)/tpm2-tools.autogened: tpm2-tools/bootstrap
$(HCP_SUBMODULES_OUT)/tpm2-tools.autogened: $(HCP_SUBMODULES_BUILDER_DEP)
$(HCP_SUBMODULES_OUT)/tpm2-tools.autogened: | $(HCP_SUBMODULES_INSTALL)
$(HCP_SUBMODULES_OUT)/tpm2-tools.autogened:
	$Q$(HCP_SUBMODULES_TPM2-TOOLS_RUN) "cd /tpm2-tools ; ./bootstrap"
	$Qtouch $@

# Bug alert: previously, setting PKG_CONFIG_PATH was enough for tpm2-tools to
# detect everything it needs. Now, it fails to find "tss2-esys>=2.4.0" and
# suggests setting TSS2_ESYS_2_3_{CFLAGS,LIBS} "to avoid the need to call
# pkg-config". Indeed, setting these works, but those same settings should have
# been picked up from the pkgconfig directory...
CMD_TPM2-TOOLS := cd /tpm2-tools ;
CMD_TPM2-TOOLS += PKG_CONFIG_PATH=$(HCP_SUBMODULES_INSTALL_DEST)/lib/pkgconfig
CMD_TPM2-TOOLS += TSS2_ESYS_2_3_CFLAGS=\"-I$(HCP_SUBMODULES_INSTALL_DEST) -I$(HCP_SUBMODULES_INSTALL_DEST)/tss2\"
CMD_TPM2-TOOLS += TSS2_ESYS_2_3_LIBS=\"-L$(HCP_SUBMODULES_INSTALL_DEST)/lib -ltss2-esys\"

CMD_TPM2-TOOLS_CFG := $(CMD_TPM2-TOOLS)
CMD_TPM2-TOOLS_CFG += ./configure --prefix=$(HCP_SUBMODULES_INSTALL_DEST)
$(HCP_SUBMODULES_OUT)/tpm2-tools.configured: $(HCP_SUBMODULES_OUT)/tpm2-tools.autogened
$(HCP_SUBMODULES_OUT)/tpm2-tools.configured: $(HCP_SUBMODULES_OUT)/tpm2-tss.installed
$(HCP_SUBMODULES_OUT)/tpm2-tools.configured:
	$Q$(HCP_SUBMODULES_TPM2-TOOLS_RUN) "$(CMD_TPM2-TOOLS_CFG)"
	$Qtouch $@

CMD_TPM2-TOOLS_COMP := $(CMD_TPM2-TOOLS)
CMD_TPM2-TOOLS_COMP += make $(SAFEBOOT_HCP_SUBMODULES_MAKE_PARALLEL)
$(HCP_SUBMODULES_OUT)/tpm2-tools.compiled: $(HCP_SUBMODULES_OUT)/tpm2-tools.configured
$(HCP_SUBMODULES_OUT)/tpm2-tools.compiled:
	$Q$(HCP_SUBMODULES_TPM2-TOOLS_RUN) "$(CMD_TPM2-TOOLS_COMP)"
	$Qtouch $@

CMD_TPM2-TOOLS_INSTALL := $(CMD_TPM2-TOOLS_COMP) install
$(HCP_SUBMODULES_OUT)/tpm2-tools.installed: $(HCP_SUBMODULES_OUT)/tpm2-tools.compiled
$(HCP_SUBMODULES_OUT)/tpm2-tools.installed:
	$Q$(HCP_SUBMODULES_TPM2-TOOLS_RUN) "$(CMD_TPM2-TOOLS_INSTALL)"
	$Qtouch $@

endif

###########
# libtpms #
###########

HCP_SUBMODULES_LIBTPMS_RUN := $(HCP_SUBMODULES_DOCKER_RUN) \
	-v $(TOP)/libtpms:/libtpms \
	$(HCP_BUILDER_DNAME) \
	bash -c

$(HCP_SUBMODULES_OUT)/libtpms.autogened: libtpms/autogen.sh
$(HCP_SUBMODULES_OUT)/libtpms.autogened: $(HCP_SUBMODULES_BUILDER_DEP)
$(HCP_SUBMODULES_OUT)/libtpms.autogened: | $(HCP_SUBMODULES_INSTALL)
$(HCP_SUBMODULES_OUT)/libtpms.autogened:
	$Q$(HCP_SUBMODULES_LIBTPMS_RUN) "cd /libtpms ; NOCONFIGURE=1 ./autogen.sh"
	$Qtouch $@

CMD_LIBTPMS_CFG := cd /libtpms ; ./configure --with-openssl --with-tpm2
CMD_LIBTPMS_CFG += --prefix=$(HCP_SUBMODULES_INSTALL_DEST)
$(HCP_SUBMODULES_OUT)/libtpms.configured: $(HCP_SUBMODULES_OUT)/libtpms.autogened
$(HCP_SUBMODULES_OUT)/libtpms.configured:
	$Q$(HCP_SUBMODULES_LIBTPMS_RUN) "$(CMD_LIBTPMS_CFG)"
	$Qtouch $@

CMD_LIBTPMS_COMPILE := cd /libtpms ; make $(SAFEBOOT_HCP_SUBMODULES_MAKE_PARALLEL)
$(HCP_SUBMODULES_OUT)/libtpms.compiled: $(HCP_SUBMODULES_OUT)/libtpms.configured
$(HCP_SUBMODULES_OUT)/libtpms.compiled:
	$Q$(HCP_SUBMODULES_LIBTPMS_RUN) "$(CMD_LIBTPMS_COMPILE)"
	$Qtouch $@

$(HCP_SUBMODULES_OUT)/libtpms.installed: $(HCP_SUBMODULES_OUT)/libtpms.compiled
$(HCP_SUBMODULES_OUT)/libtpms.installed:
	$Q$(HCP_SUBMODULES_LIBTPMS_RUN) "cd /libtpms ; make install"
	$Qtouch $@

#########
# swtpm #
#########

HCP_SUBMODULES_SWTPM_RUN := $(HCP_SUBMODULES_DOCKER_RUN) \
	-v $(TOP)/swtpm:/swtpm \
	$(HCP_BUILDER_DNAME) \
	bash -c

$(HCP_SUBMODULES_OUT)/swtpm.autogened: swtpm/autogen.sh
$(HCP_SUBMODULES_OUT)/swtpm.autogened: $(HCP_SUBMODULES_BUILDER_DEP)
$(HCP_SUBMODULES_OUT)/swtpm.autogened: | $(HCP_SUBMODULES_INSTALL)
$(HCP_SUBMODULES_OUT)/swtpm.autogened:
	$Q$(HCP_SUBMODULES_SWTPM_RUN) "cd /swtpm ; NOCONFIGURE=1 ./autogen.sh"
	$Qtouch $@

CMD_SWTPM_CFG := cd /swtpm ;
CMD_SWTPM_CFG += LIBTPMS_LIBS='-L$(HCP_SUBMODULES_INSTALL_DEST)/lib -ltpms'
CMD_SWTPM_CFG += LIBTPMS_CFLAGS='-I$(HCP_SUBMODULES_INSTALL_DEST)/include'
CMD_SWTPM_CFG += ./configure --with-openssl --with-tpm2 --prefix=$(HCP_SUBMODULES_INSTALL_DEST)

$(HCP_SUBMODULES_OUT)/swtpm.configured: $(HCP_SUBMODULES_OUT)/swtpm.autogened
$(HCP_SUBMODULES_OUT)/swtpm.configured: $(HCP_SUBMODULES_OUT)/libtpms.installed
$(HCP_SUBMODULES_OUT)/swtpm.configured:
	$Q$(HCP_SUBMODULES_SWTPM_RUN) "$(CMD_SWTPM_CFG)"
	$Qtouch $@

$(HCP_SUBMODULES_OUT)/swtpm.compiled: $(HCP_SUBMODULES_OUT)/swtpm.configured
$(HCP_SUBMODULES_OUT)/swtpm.compiled:
	$Q$(HCP_SUBMODULES_SWTPM_RUN) "cd /swtpm ; make $(SAFEBOOT_HCP_SUBMODULES_MAKE_PARALLEL)"
	$Qtouch $@

$(HCP_SUBMODULES_OUT)/swtpm.installed: $(HCP_SUBMODULES_OUT)/swtpm.compiled
$(HCP_SUBMODULES_OUT)/swtpm.installed:
	$Q$(HCP_SUBMODULES_SWTPM_RUN) "cd /swtpm ; make install"
	$Qtouch $@

##################
# install.tar.gz #
##################

TGZ_CMD := cd /put_it_here ;
TGZ_CMD += tar zcf install.tar.gz $(HCP_SUBMODULES_INSTALL_DEST) ;
TGZ_CMD += chown --reference=swtpm.installed install.tar.gz

$(HCP_SUBMODULES_OUT)/install.tar.gz: $(HCP_SUBMODULES_OUT)/swtpm.installed
ifdef SAFEBOOT_HCP_SUBMODULES_TPM2
$(HCP_SUBMODULES_OUT)/install.tar.gz: $(HCP_SUBMODULES_OUT)/tpm2-tools.installed
endif
$(HCP_SUBMODULES_OUT)/install.tar.gz:
	$Q$(HCP_SUBMODULES_DOCKER_RUN) \
		-v $(HCP_SUBMODULES_OUT):/put_it_here \
		$(HCP_BUILDER_DNAME) bash -c "$(TGZ_CMD)"
$(HCP_SUBMODULES_OUT)/install.tar.gz.inject: $(HCP_SUBMODULES_OUT)/install.tar.gz
	$Qecho "$(call tarball_extract,install)" > $@

# A wrapper target to build the submodules
hcp_submodules: $(HCP_SUBMODULES_OUT)/install.tar.gz

# Cleanup sequence
# - if (out/install.tar.gz)
#   - rm out/install.tar.gz
# - if (out/swtpm.installed)
#   - cd /swtpm && make uninstall
#   - rm out/swtpm.installed
# - if (out/libtpms.installed)
#   - cd /libtpms && make uninstall
#   - rm out/libtpms.installed
# - if (out/install/ && it contains files)
#   - if (!FORCE), error and fail
#   - assist_cleanup volume /install
# - if (out/swtpm.*)
#   - assist_cleanup submodule swtpm (chown)
#   - rm out/swtpm.*
# - if (out/libtpms.*)
#   - assist_cleanup submodule libtpms (chown)
#   - rm out/libtpms.*
# - rmdir out/

ifeq (yes,$(shell stat $(HCP_SUBMODULES_INSTALL) > /dev/null 2>&1 && echo yes))
SUBMODULES_INSTALLED_FILES := $(find $(HCP_SUBMODULES_INSTALL)/ -type f 2> /dev/null)
endif

clean_hcp_submodules:
	$Qrm -f $(HCP_SUBMODULES_OUT)/install.tar.gz
ifeq (yes,$(shell stat $(HCP_SUBMODULES_INSTALL) > /dev/null 2>&1 && echo yes))
	$QUTIL_IMAGE=$(SAFEBOOT_HCP_BASE) \
		$(ASSIST_CLEANUP) volume $(HCP_SUBMODULES_INSTALL)
endif
	$QUTIL_IMAGE=$(SAFEBOOT_HCP_BASE) \
		$(ASSIST_CLEANUP) submodule $(TOP)/swtpm autogen.sh
	$QUTIL_IMAGE=$(SAFEBOOT_HCP_BASE) \
		$(ASSIST_CLEANUP) submodule $(TOP)/libtpms autogen.sh
	$QUTIL_IMAGE=$(SAFEBOOT_HCP_BASE) \
		$(ASSIST_CLEANUP) submodule $(TOP)/tpm2-tools bootstrap
	$QUTIL_IMAGE=$(SAFEBOOT_HCP_BASE) \
		$(ASSIST_CLEANUP) submodule $(TOP)/tpm2-tss bootstrap
	$Qrm -rf $(HCP_SUBMODULES_OUT)

# Cleanup ordering
clean_hcp_builder: clean_hcp_submodules
