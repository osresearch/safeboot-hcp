HCP_ENROLLSVC_SRC := $(HCP_SRC)/enrollsvc
HCP_ENROLLSVC_OUT := $(HCP_OUT)/enrollsvc
HCP_ENROLLSVC_DNAME := $(SAFEBOOT_HCP_DSPACE)enrollsvc$(SAFEBOOT_HCP_DTAG)

$(HCP_ENROLLSVC_OUT): | $(HCP_OUT)
MDIRS += $(HCP_ENROLLSVC_OUT)

# Some summary notes about the enrollment service, a.k.a. "enrollsvc".
#
# This service consists of two sub-services; "mgmt" and "repl", which perform
# complementary functions but operate on common state (a directory bind-mounted
# into both containers);
#  * The common state consists of;
#    - the "enrollment database", currently implemented as a git repository.
#    - a "msgbus" directory, into which;
#      - the services write their stdout/stderr,
#      - control software outside the service containers can write commands to
#        be picked up by the services. Currently, this is limited to "stop"
#        functionality, which writes "die" to a file the service is
#        "tail_wait"ing, triggering it to exit.
#  * enrollsvc::mgmt provides the enrollment/registration functionality;
#    - The common state is mounted read-write.
#    - The enrollment interface is implemented as a flask app.
#      - API exposed at http[s]://<server>[:port]/v1/{add,query,delete,find}
#      - A human/interactive web UI lives at http[s]://<server>[:port]/
#    - Enrollment of a host+ek.pub 2-tuple triggers a (modular, configurable)
#      asset-generation process, to provision credentials and other host
#      secrets that are immediately sealed to the enrolled host's TPM and to a
#      recovery/break-glass credential before insertion into the database.
#    - The flask app runs as a non-root (FLASK_USER) account in the container.
#    - The asset-generation and database-write processes run as a different,
#      non-root (DB_USER) account in the container.
#    - The flask app handlers invoke the asset-generation and querying
#      functions via constrained sudo rules, to prevent environment
#      contamination and limit information-passing to just the command
#      arguments.
#  * enrollsvc::repl provides a replication service to downstream attestation
#    service instances (attestsvc::repl).
#    - The common state is mounted read-only!
#    - The replication service uses "git-daemon" directly, running as a
#      non-root (DB_USER) account in the container.
#    - Use of the same DB_USER account (as used in the asset-generation
#      process) is to simplify file-system permissioning (user/group ownership
#      of database files).
#      - This does not leak any visibility to the asset-generation process in
#        the other container, only the database is present/shared/mounted in
#        both containers.
#      - The database (directory) is read-only at the mount level, so we don't
#        need account separation to protect the database from modification by
#        the replication functionality.

# wrapper targets to build the "enrollsvc" images
hcp_enrollsvc: $(HCP_ENROLLSVC_OUT)/built

# A "DB_USER" account is created so that asset-generation and DB manipulation
# doesn't require root privs.
DB_USER := db_user
# The enrollsvc-mgmt container also runs the flask app, which needs to be priv
# separated from everything else (especially from the asset-generation/DB
# code), so it has its own non-root account.
FLASK_USER := flask_user


#############
# enrollsvc #
#############

# Include the submodule bundle
HCP_ENROLLSVC_PATHS += $(HCP_ENROLLSVC_OUT)/install.tar.gz
$(HCP_ENROLLSVC_OUT)/install.tar.gz: | $(HCP_ENROLLSVC_OUT)
$(HCP_ENROLLSVC_OUT)/install.tar.gz: $(HCP_SUBMODULES_OUT)/install.tar.gz
$(HCP_ENROLLSVC_OUT)/install.tar.gz:
	$Qcp $< $@

# And the safeboot bundle
HCP_ENROLLSVC_PATHS += $(HCP_ENROLLSVC_OUT)/safeboot.tar.gz
$(HCP_ENROLLSVC_OUT)/safeboot.tar.gz: | $(HCP_ENROLLSVC_OUT)
$(HCP_ENROLLSVC_OUT)/safeboot.tar.gz: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz
$(HCP_ENROLLSVC_OUT)/safeboot.tar.gz:
	$Qcp $< $@

# And the hcp-{common,enrollsvc} bundles
HCP_ENROLLSVC_PATHS += $(HCP_ENROLLSVC_OUT)/hcp-common.tar.gz
HCP_ENROLLSVC_PATHS += $(HCP_ENROLLSVC_OUT)/hcp-enrollsvc.tar.gz
$(HCP_ENROLLSVC_OUT)/hcp-common.tar.gz: | $(HCP_ENROLLSVC_OUT)
$(HCP_ENROLLSVC_OUT)/hcp-common.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz
$(HCP_ENROLLSVC_OUT)/hcp-common.tar.gz:
	$Qcp $< $@
$(HCP_ENROLLSVC_OUT)/hcp-enrollsvc.tar.gz: | $(HCP_ENROLLSVC_OUT)
$(HCP_ENROLLSVC_OUT)/hcp-enrollsvc.tar.gz: $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz
$(HCP_ENROLLSVC_OUT)/hcp-enrollsvc.tar.gz:
	$Qcp $< $@

# Dockerfile-generation.
$(HCP_ENROLLSVC_OUT)/Dockerfile: | $(HCP_ENROLLSVC_OUT)
$(HCP_ENROLLSVC_OUT)/Dockerfile: $(HCP_ENROLLSVC_SRC)/Makefile
$(HCP_ENROLLSVC_OUT)/Dockerfile: $(HCP_ENROLLSVC_SRC)/Dockerfile
$(HCP_ENROLLSVC_OUT)/Dockerfile: $(HCP_SUBMODULES_OUT)/install.tar.gz.inject
$(HCP_ENROLLSVC_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject
$(HCP_ENROLLSVC_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject
$(HCP_ENROLLSVC_OUT)/Dockerfile: $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz.inject
$(HCP_ENROLLSVC_OUT)/Dockerfile:
	$Qecho "FROM $(HCP_BASE_DNAME)" > $@
	$Qcat $(HCP_ENROLLSVC_SRC)/Dockerfile >> $@
	$Qcat $(HCP_SUBMODULES_OUT)/install.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject >> $@
	$Qcat $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz.inject >> $@
	$Qecho "$(call tarball_finalize)" >> $@

# "docker build" to create the container image (recipe only)
$(HCP_ENROLLSVC_OUT)/built: $(HCP_ENROLLSVC_OUT)/Dockerfile
$(HCP_ENROLLSVC_OUT)/built: $(HCP_ENROLLSVC_PATHS)
$(HCP_ENROLLSVC_OUT)/built: $(HCP_BASE_TOUCHFILE)
$(HCP_ENROLLSVC_OUT)/built:
	$Qdocker build -t $(HCP_ENROLLSVC_DNAME) \
	               -f $(HCP_ENROLLSVC_OUT)/Dockerfile \
	               --build-arg DB_USER=$(DB_USER) \
	               --build-arg FLASK_USER=$(FLASK_USER) \
	               $(HCP_ENROLLSVC_OUT)
	$Qtouch $@

# "docker image rm" to remove the container image (interface and recipe)
clean_hcp_enrollsvc: | preclean_hcp
ifneq (,$(filter $(HCP_ENROLLSVC_DNAME),$(HCP_EXISTING_IMAGES)))
	$Qdocker image rm $(HCP_ENROLLSVC_DNAME)
endif
	$Qrm -rf $(HCP_ENROLLSVC_OUT)


################
# cleanup deps #
################

clean_hcp_base: clean_hcp_enrollsvc
