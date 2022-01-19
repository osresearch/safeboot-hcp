HCP_APPS_OUT := $(HCP_OUT)/apps
HCP_APPS_SRC := $(HCP_SRC)/apps

$(HCP_APPS_OUT): | $(HCP_OUT)
MDIRS += $(HCP_APPS_OUT)

HCP_APPS_BASE := $(HCP_BASE_DNAME)
HCP_APPS_BASE_TOUCH := $(HCP_BASE_TOUCHFILE)

define app_add
$(HCP_APPS_OUT)/created.$1: $(HCP_APPS_OUT)/$1/$3
$(HCP_APPS_OUT)/$1/$3: | $(HCP_APPS_OUT)/$1/
$(HCP_APPS_OUT)/$1/$3: $2$3
	$Qcp $$< $$@
endef

define app_create
$(HCP_APPS_OUT)/$1/: | $(HCP_APPS_OUT)
MDIRS += $(HCP_APPS_OUT)/$1/
$(HCP_APPS_OUT)/created.$1: | $(HCP_APPS_OUT)/$1/Dockerfile
$(HCP_APPS_OUT)/created.$1:
	$Qecho "Building container image $1 ($(HCP_DSPACE)$1$(HCP_DTAG))"
	$Qdocker build \
		-t $(HCP_DSPACE)$1$(HCP_DTAG) \
		-f $(HCP_APPS_OUT)/$1/Dockerfile \
		$2 \
		$(HCP_APPS_OUT)
	$Qtouch $$@
$1: $(HCP_APPS_OUT)/created.$1
ALL += $1
APPS += $1
ifneq (,$(wildcard $(HCP_APPS_OUT)/$1))
clean_$1:
ifneq (,$(wildcard $(HCP_APPS_OUT)/created.$1))
	$Qecho "Removing container image $1 ($(HCP_DSPACE)$1$(HCP_DTAG))"
	$Qdocker image rm $(HCP_DSPACE)$1$(HCP_DTAG)
	rm $(HCP_APPS_OUT)/created.$1
endif
	rm -rf $(HCP_APPS_OUT)/$1
clean_apps: clean_$1
endif
$(foreach i,$(shell ls -1 $(HCP_APPS_SRC)/$1 | grep -v "Dockerfile"),\
	$(eval $(call app_add,$1,$(HCP_APPS_SRC)/$1/,$i)))
$(HCP_APPS_OUT)/created.$1: $(HCP_APPS_OUT)/$1/Dockerfile
$(HCP_APPS_OUT)/created.$1: $(HCP_APPS_BASE_TOUCH)
$(HCP_APPS_OUT)/$1/Dockerfile: $(HCP_APPS_OUT)/$1/hcp.Dockerfile
	$Qecho "FROM $(HCP_APPS_BASE)" > $$@
	$Qcat $$< >> $$@
endef

#########################
# Common ancestor image #
#########################

$(eval $(call app_create,common))
$(eval $(call app_add,common,$(HCP_APPS_SRC)/common/,hcp.Dockerfile))
$(eval $(call app_add,common,$(HCP_SAFEBOOT_OUT)/,safeboot.tar.gz))
$(eval $(call app_add,common,$(HCP_TPMWARE_OUT)/,install.tar.gz))

# And the point - change the base layer (and dependency touchfile) used for
# subsequent apps;
HCP_APPS_BASE := $(HCP_DSPACE)common$(HCP_DTAG)
HCP_APPS_BASE_TOUCH := $(HCP_APPS_OUT)/created.common

######################
# Enrollment Service #
######################

$(eval $(call app_create,enrollsvc,))
$(eval $(call app_add,enrollsvc,$(HCP_APPS_SRC)/enrollsvc/,hcp.Dockerfile))

#######################
# Attestation Service #
#######################

$(eval $(call app_create,attestsvc,))
$(eval $(call app_add,attestsvc,$(HCP_APPS_SRC)/attestsvc/,hcp.Dockerfile))

########################
# Software TPM Service #
########################

$(eval $(call app_create,swtpmsvc,))
$(eval $(call app_add,swtpmsvc,$(HCP_APPS_SRC)/swtpmsvc/,hcp.Dockerfile))
$(eval $(call app_add,swtpmsvc,$(TOP)/api/,enroll_api.py))

######################
# Attestation Client #
######################

$(eval $(call app_create,client,))
$(eval $(call app_add,client,$(HCP_APPS_SRC)/client/,hcp.Dockerfile))

############
# Caboodle #
############

# This is a union of the other apps, plus our own bits

$(eval $(call app_create,caboodle,))
# These dependencies ensure that the "docker build" won't run until the sources
# for all the component containers are replicated / up-to-date.
$(HCP_APPS_OUT)/created.caboodle: $(HCP_APPS_OUT)/created.enrollsvc
$(HCP_APPS_OUT)/created.caboodle: $(HCP_APPS_OUT)/created.attestsvc
$(HCP_APPS_OUT)/created.caboodle: $(HCP_APPS_OUT)/created.swtpmsvc
$(HCP_APPS_OUT)/created.caboodle: $(HCP_APPS_OUT)/created.client
# The following avoids the usual replicate-and-modify process for the
# hcp.Dockerfile for caboodle, because we actually want to join it with the
# other Dockerfiles.
$(HCP_APPS_OUT)/caboodle/hcp.Dockerfile: $(HCP_APPS_OUT)/enrollsvc/hcp.Dockerfile
$(HCP_APPS_OUT)/caboodle/hcp.Dockerfile: $(HCP_APPS_OUT)/attestsvc/hcp.Dockerfile
$(HCP_APPS_OUT)/caboodle/hcp.Dockerfile: $(HCP_APPS_OUT)/swtpmsvc/hcp.Dockerfile
$(HCP_APPS_OUT)/caboodle/hcp.Dockerfile: $(HCP_APPS_OUT)/client/hcp.Dockerfile
$(HCP_APPS_OUT)/caboodle/hcp.Dockerfile: $(HCP_APPS_SRC)/caboodle/hcp.Dockerfile
	$Qecho "# The following is a concatenation of Dockerfiles" > $@
	$Qcat $(HCP_APPS_OUT)/enrollsvc/hcp.Dockerfile >> $@
	$Qcat $(HCP_APPS_OUT)/attestsvc/hcp.Dockerfile >> $@
	$Qcat $(HCP_APPS_OUT)/swtpmsvc/hcp.Dockerfile >> $@
	$Qcat $(HCP_APPS_OUT)/client/hcp.Dockerfile >> $@
	$Qcat $(HCP_APPS_SRC)/caboodle/hcp.Dockerfile >> $@

###########
# Wrapper #
###########

apps: $(APPS)

# Global cleanup
ifneq (,$(wildcard $(HCP_APPS_OUT)))
clean_apps:
	$Qrmdir $(HCP_APPS_OUT)
clean: clean_apps
endif
