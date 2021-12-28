HCP_CLIENT_SRC := $(HCP_SRC)/client
HCP_CLIENT_OUT := $(HCP_OUT)/client
HCP_CLIENT_DNAME := $(SAFEBOOT_HCP_DSPACE)client$(SAFEBOOT_HCP_DTAG)

$(HCP_CLIENT_OUT): | $(HCP_OUT)
MDIRS += $(HCP_CLIENT_OUT)

# wrapper target to build the "client" image
hcp_client: $(HCP_CLIENT_OUT)/built

# Include the submodule bundle
HCP_CLIENT_PATHS += $(HCP_CLIENT_OUT)/install.tar.gz
$(HCP_CLIENT_OUT)/install.tar.gz: | $(HCP_CLIENT_OUT)
$(HCP_CLIENT_OUT)/install.tar.gz: $(HCP_SUBMODULES_OUT)/install.tar.gz
$(HCP_CLIENT_OUT)/install.tar.gz:
	$Qcp $< $@

# And the safeboot bundle
HCP_CLIENT_PATHS += $(HCP_CLIENT_OUT)/safeboot.tar.gz
$(HCP_CLIENT_OUT)/safeboot.tar.gz: | $(HCP_CLIENT_OUT)
$(HCP_CLIENT_OUT)/safeboot.tar.gz: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz
$(HCP_CLIENT_OUT)/safeboot.tar.gz:
	$Qcp $< $@

# And the hcp-{common,client} bundles
HCP_CLIENT_PATHS += $(HCP_CLIENT_OUT)/hcp-common.tar.gz
HCP_CLIENT_PATHS += $(HCP_CLIENT_OUT)/hcp-client.tar.gz
$(HCP_CLIENT_OUT)/hcp-common.tar.gz: | $(HCP_CLIENT_OUT)
$(HCP_CLIENT_OUT)/hcp-common.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz
$(HCP_CLIENT_OUT)/hcp-common.tar.gz:
	$Qcp $< $@
$(HCP_CLIENT_OUT)/hcp-client.tar.gz: | $(HCP_CLIENT_OUT)
$(HCP_CLIENT_OUT)/hcp-client.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz
$(HCP_CLIENT_OUT)/hcp-client.tar.gz:
	$Qcp $< $@

# Dockerfile-generation.
$(HCP_CLIENT_OUT)/Dockerfile: | $(HCP_CLIENT_OUT)
$(HCP_CLIENT_OUT)/Dockerfile: $(HCP_CLIENT_SRC)/Makefile
$(HCP_CLIENT_OUT)/Dockerfile: $(HCP_CLIENT_SRC)/Dockerfile
$(HCP_CLIENT_OUT)/Dockerfile: $(HCP_SUBMODULES_OUT)/install.tar.gz.inject
$(HCP_CLIENT_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject
$(HCP_CLIENT_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject
$(HCP_CLIENT_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz.inject
$(HCP_CLIENT_OUT)/Dockerfile:
	$Qecho "FROM $(HCP_BASE_DNAME)" > $@
	$Qcat $(HCP_CLIENT_SRC)/Dockerfile >> $@
	$Qcat $(HCP_SUBMODULES_OUT)/install.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz.inject >> $@
	$Qecho "$(call tarball_finalize)" >> $@

# "docker build" to create the container image (recipe only)
$(HCP_CLIENT_OUT)/built: $(HCP_CLIENT_OUT)/Dockerfile
$(HCP_CLIENT_OUT)/built: $(HCP_CLIENT_PATHS)
$(HCP_CLIENT_OUT)/built: $(HCP_BASE_TOUCHFILE)
$(HCP_CLIENT_OUT)/built:
	$Qdocker build -t $(HCP_CLIENT_DNAME) \
	               -f $(HCP_CLIENT_OUT)/Dockerfile \
	               $(HCP_CLIENT_OUT)
	$Qtouch $@

# "docker image rm" to remove the container image (interface and recipe)
clean_hcp_client: | preclean_hcp
ifneq (,$(filter $(HCP_CLIENT_DNAME),$(HCP_EXISTING_IMAGES)))
	$Qdocker image rm $(HCP_CLIENT_DNAME)
endif
	$Qrm -rf $(HCP_CLIENT_OUT)

# Cleanup ordering
clean_hcp_base: clean_hcp_client
