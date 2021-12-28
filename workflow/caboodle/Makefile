# This "caboodle" thing is a little special, relative to the other targets.
# Like hcp/client, it builds an image for use as a synchronous function, rather
# than for running asynchronous services like everything else. But unlike
# client, which provides a synchronous "_run" target to execute a particular
# script, caboodle's "_run" target runs a bash session (and adds the "-t" flag
# to the docker-run invocation).
#
# It is also special in the way it builds. It concatenates all other (relevant)
# Dockerfiles together to form a kind of "union" container. The purpose of this
# is to have an image that can run and which contains within it _all_ of the
# HCP functionality in one colocated entity. For one thing, this allows a more
# traditional "single-host" development environment for messing around with
# scripting, but puts it in one mega container as an alternative to doing it
# literally on the host.

HCP_CABOODLE_SRC := $(HCP_SRC)/caboodle
HCP_CABOODLE_OUT := $(HCP_OUT)/caboodle
HCP_CABOODLE_DNAME := $(SAFEBOOT_HCP_DSPACE)caboodle$(SAFEBOOT_HCP_DTAG)

$(HCP_CABOODLE_OUT): | $(HCP_OUT)
MDIRS += $(HCP_CABOODLE_OUT)

# wrapper target to build the "caboodle" image
hcp_caboodle: $(HCP_CABOODLE_OUT)/built

# Include the submodule bundle
HCP_CABOODLE_PATHS += $(HCP_CABOODLE_OUT)/install.tar.gz
$(HCP_CABOODLE_OUT)/install.tar.gz: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/install.tar.gz: $(HCP_SUBMODULES_OUT)/install.tar.gz
$(HCP_CABOODLE_OUT)/install.tar.gz:
	$Qcp $< $@

# And the safeboot bundle
HCP_CABOODLE_PATHS += $(HCP_CABOODLE_OUT)/safeboot.tar.gz
$(HCP_CABOODLE_OUT)/safeboot.tar.gz: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/safeboot.tar.gz: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz
$(HCP_CABOODLE_OUT)/safeboot.tar.gz:
	$Qcp $< $@

# And all the hcp-{common,enrollsvc,attestsvc,swtpmsvc,client,caboodle} bundles
HCP_CABOODLE_PATHS += $(HCP_CABOODLE_OUT)/hcp-common.tar.gz
HCP_CABOODLE_PATHS += $(HCP_CABOODLE_OUT)/hcp-enrollsvc.tar.gz
HCP_CABOODLE_PATHS += $(HCP_CABOODLE_OUT)/hcp-attestsvc.tar.gz
HCP_CABOODLE_PATHS += $(HCP_CABOODLE_OUT)/hcp-swtpmsvc.tar.gz
HCP_CABOODLE_PATHS += $(HCP_CABOODLE_OUT)/hcp-client.tar.gz
HCP_CABOODLE_PATHS += $(HCP_CABOODLE_OUT)/hcp-caboodle.tar.gz
$(HCP_CABOODLE_OUT)/hcp-common.tar.gz: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/hcp-common.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz
$(HCP_CABOODLE_OUT)/hcp-common.tar.gz:
	$Qcp $< $@
$(HCP_CABOODLE_OUT)/hcp-enrollsvc.tar.gz: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/hcp-enrollsvc.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz
$(HCP_CABOODLE_OUT)/hcp-enrollsvc.tar.gz:
	$Qcp $< $@
$(HCP_CABOODLE_OUT)/hcp-attestsvc.tar.gz: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/hcp-attestsvc.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz
$(HCP_CABOODLE_OUT)/hcp-attestsvc.tar.gz:
	$Qcp $< $@
$(HCP_CABOODLE_OUT)/hcp-swtpmsvc.tar.gz: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/hcp-swtpmsvc.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz
$(HCP_CABOODLE_OUT)/hcp-swtpmsvc.tar.gz:
	$Qcp $< $@
$(HCP_CABOODLE_OUT)/hcp-client.tar.gz: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/hcp-client.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz
$(HCP_CABOODLE_OUT)/hcp-client.tar.gz:
	$Qcp $< $@
$(HCP_CABOODLE_OUT)/hcp-caboodle.tar.gz: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/hcp-caboodle.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz
$(HCP_CABOODLE_OUT)/hcp-caboodle.tar.gz:
	$Qcp $< $@

# Dockerfile-generation.
$(HCP_CABOODLE_OUT)/Dockerfile: | $(HCP_CABOODLE_OUT)
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_CABOODLE_SRC)/Makefile
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_CABOODLE_SRC)/Dockerfile
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_ENROLLSVC_SRC)/Dockerfile
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_ATTESTSVC_SRC)/Dockerfile
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SWTPMSVC_SRC)/Dockerfile
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_CLIENT_SRC)/Dockerfile
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_CABOODLE_SRC)/Dockerfile
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SUBMODULES_OUT)/install.tar.gz.inject
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz.inject
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz.inject
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz.inject
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz.inject
$(HCP_CABOODLE_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz.inject
$(HCP_CABOODLE_OUT)/Dockerfile:
	$Qecho "FROM $(HCP_BASE_DNAME)" > $@
	$Qcat $(HCP_ENROLLSVC_SRC)/Dockerfile >> $@
	$Qcat $(HCP_ATTESTSVC_SRC)/Dockerfile >> $@
	$Qcat $(HCP_SWTPMSVC_SRC)/Dockerfile >> $@
	$Qcat $(HCP_CLIENT_SRC)/Dockerfile >> $@
	$Qcat $(HCP_SUBMODULES_OUT)/install.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz.inject >> $@
	$Qecho "$(call tarball_finalize)" >> $@
	$Qcat $(HCP_CABOODLE_SRC)/Dockerfile >> $@

# From enrollsvc/Makefile;
DB_USER := db_user
FLASK_USER := flask_user
# From attestsvc/Makefile;
HCP_USER := lowlyuser

# "docker build" to create the container image (recipe only)
$(HCP_CABOODLE_OUT)/built: $(HCP_CABOODLE_OUT)/Dockerfile
$(HCP_CABOODLE_OUT)/built: $(HCP_CABOODLE_PATHS)
$(HCP_CABOODLE_OUT)/built: $(HCP_BASE_TOUCHFILE)
$(HCP_CABOODLE_OUT)/built:
	$Qdocker build -t $(HCP_CABOODLE_DNAME) \
	               -f $(HCP_CABOODLE_OUT)/Dockerfile \
	               --build-arg DB_USER=$(DB_USER) \
	               --build-arg FLASK_USER=$(FLASK_USER) \
	               --build-arg HCP_USER=$(HCP_USER) \
	               $(HCP_CABOODLE_OUT)
	$Qtouch $@

# "docker image rm" to remove the container image (interface and recipe)
clean_hcp_caboodle: | preclean_hcp
ifneq (,$(filter $(HCP_CABOODLE_DNAME),$(HCP_EXISTING_IMAGES)))
	$Qdocker image rm $(HCP_CABOODLE_DNAME)
endif
	$Qrm -rf $(HCP_CABOODLE_OUT)

# Cleanup ordering
clean_hcp_base: clean_hcp_caboodle
