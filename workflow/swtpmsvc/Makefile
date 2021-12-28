HCP_SWTPMSVC_SRC := $(HCP_SRC)/swtpmsvc
HCP_SWTPMSVC_OUT := $(HCP_OUT)/swtpmsvc
HCP_SWTPMSVC_DNAME := $(SAFEBOOT_HCP_DSPACE)swtpmsvc$(SAFEBOOT_HCP_DTAG)

$(HCP_SWTPMSVC_OUT): | $(HCP_OUT)
MDIRS += $(HCP_SWTPMSVC_OUT)

# wrapper target to build the "swtpm" image
hcp_swtpmsvc: $(HCP_SWTPMSVC_OUT)/built

# Include the submodule bundle
HCP_SWTPMSVC_PATHS += $(HCP_SWTPMSVC_OUT)/install.tar.gz
$(HCP_SWTPMSVC_OUT)/install.tar.gz: | $(HCP_SWTPMSVC_OUT)
$(HCP_SWTPMSVC_OUT)/install.tar.gz: $(HCP_SUBMODULES_OUT)/install.tar.gz
$(HCP_SWTPMSVC_OUT)/install.tar.gz:
	$Qcp $< $@

# And the safeboot bundle
HCP_SWTPMSVC_PATHS += $(HCP_SWTPMSVC_OUT)/safeboot.tar.gz
$(HCP_SWTPMSVC_OUT)/safeboot.tar.gz: | $(HCP_SWTPMSVC_OUT)
$(HCP_SWTPMSVC_OUT)/safeboot.tar.gz: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz
$(HCP_SWTPMSVC_OUT)/safeboot.tar.gz:
	$Qcp $< $@

# And the hcp-{common,swtpmsvc} bundles
HCP_SWTPMSVC_PATHS += $(HCP_SWTPMSVC_OUT)/hcp-common.tar.gz
HCP_SWTPMSVC_PATHS += $(HCP_SWTPMSVC_OUT)/hcp-swtpmsvc.tar.gz
$(HCP_SWTPMSVC_OUT)/hcp-common.tar.gz: | $(HCP_SWTPMSVC_OUT)
$(HCP_SWTPMSVC_OUT)/hcp-common.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz
$(HCP_SWTPMSVC_OUT)/hcp-common.tar.gz:
	$Qcp $< $@
$(HCP_SWTPMSVC_OUT)/hcp-swtpmsvc.tar.gz: | $(HCP_SWTPMSVC_OUT)
$(HCP_SWTPMSVC_OUT)/hcp-swtpmsvc.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz
$(HCP_SWTPMSVC_OUT)/hcp-swtpmsvc.tar.gz:
	$Qcp $< $@

# Dockerfile-generation.
$(HCP_SWTPMSVC_OUT)/Dockerfile: | $(HCP_SWTPMSVC_OUT)
$(HCP_SWTPMSVC_OUT)/Dockerfile: $(HCP_SWTPMSVC_SRC)/Makefile
$(HCP_SWTPMSVC_OUT)/Dockerfile: $(HCP_SWTPMSVC_SRC)/Dockerfile
$(HCP_SWTPMSVC_OUT)/Dockerfile: $(HCP_SUBMODULES_OUT)/install.tar.gz.inject
$(HCP_SWTPMSVC_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject
$(HCP_SWTPMSVC_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject
$(HCP_SWTPMSVC_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz.inject
$(HCP_SWTPMSVC_OUT)/Dockerfile:
	$Qecho "FROM $(HCP_BASE_DNAME)" > $@
	$Qcat $(HCP_SWTPMSVC_SRC)/Dockerfile >> $@
	$Qcat $(HCP_SUBMODULES_OUT)/install.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz.inject >> $@
	$Qecho "$(call tarball_finalize)" >> $@

# "docker build" to create the container image (recipe only)
$(HCP_SWTPMSVC_OUT)/built: $(HCP_SWTPMSVC_OUT)/Dockerfile
$(HCP_SWTPMSVC_OUT)/built: $(HCP_SWTPMSVC_PATHS)
$(HCP_SWTPMSVC_OUT)/built: $(HCP_BASE_TOUCHFILE)
$(HCP_SWTPMSVC_OUT)/built:
	$Qdocker build -t $(HCP_SWTPMSVC_DNAME) \
	               -f $(HCP_SWTPMSVC_OUT)/Dockerfile \
	               $(HCP_SWTPMSVC_OUT)
	$Qtouch $@

# "docker image rm" to remove the container image (interface and recipe)
clean_hcp_swtpmsvc: | preclean_hcp
ifneq (,$(filter $(HCP_SWTPMSVC_DNAME),$(HCP_EXISTING_IMAGES)))
	$Qdocker image rm $(HCP_SWTPMSVC_DNAME)
endif
	$Qrm -rf $(HCP_SWTPMSVC_OUT)

# Cleanup ordering
clean_hcp_base: clean_hcp_swtpmsvc
