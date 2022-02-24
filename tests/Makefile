HCP_TESTS_OUT := $(HCP_OUT)/tests
HCP_TESTS_SRC := $(TOP)/tests

$(HCP_TESTS_OUT): | $(HCP_OUT)
MDIRS += $(HCP_TESTS_OUT)

#####################
# Testing container #
#####################

# NB, the following is mostly expanded from the app_create() function
# in src/apps/Makefile, and tweaked.

$(HCP_TESTS_OUT)/soakhost: | $(HCP_TESTS_OUT)
MDIRS += $(HCP_TESTS_OUT)/soakhost

$(HCP_TESTS_OUT)/soakhost/Dockerfile: | $(HCP_TESTS_OUT)/soakhost
$(HCP_TESTS_OUT)/soakhost/Dockerfile: $(HCP_TESTS_SRC)/soakhost/hcp.Dockerfile
$(HCP_TESTS_OUT)/soakhost/Dockerfile:
	$Qecho "FROM $(HCP_DSPACE)caboodle$(HCP_DTAG)" > $@
	$Qcat $(HCP_TESTS_SRC)/soakhost/hcp.Dockerfile >> $@

$(HCP_TESTS_OUT)/soakhost/soak.sh: | $(HCP_TESTS_OUT)/soakhost
$(HCP_TESTS_OUT)/soakhost/soak.sh: $(HCP_TESTS_SRC)/soakhost/soak.sh
	$Qcp $< $@

$(HCP_TESTS_OUT)/soakhost/greeting.sh: | $(HCP_TESTS_OUT)/soakhost
$(HCP_TESTS_OUT)/soakhost/greeting.sh: $(HCP_TESTS_SRC)/soakhost/greeting.sh
	$Qcp $< $@

$(HCP_TESTS_OUT)/created.soakhost: $(HCP_TESTS_OUT)/soakhost/Dockerfile
$(HCP_TESTS_OUT)/created.soakhost: $(HCP_TESTS_OUT)/soakhost/soak.sh
$(HCP_TESTS_OUT)/created.soakhost: $(HCP_TESTS_OUT)/soakhost/greeting.sh
$(HCP_TESTS_OUT)/created.soakhost: $(HCP_APPS_OUT)/created.caboodle
$(HCP_TESTS_OUT)/created.soakhost:
	$Qecho "Building container image soakhost ($(HCP_DSPACE)soakhost$(HCP_DTAG))"
	$Qdocker build \
		-t $(HCP_DSPACE)soakhost$(HCP_DTAG) \
		-f $(HCP_TESTS_OUT)/soakhost/Dockerfile \
		$2 \
		$(HCP_TESTS_OUT)/soakhost
	$Qtouch $@

soakhost: $(HCP_TESTS_OUT)/created.soakhost
ALL += soakhost
ifneq (,$(wildcard $(HCP_TESTS_OUT)/soakhost))
clean_soakhost:
ifneq (,$(wildcard $(HCP_TESTS_OUT)/created.soakhost))
	$Qecho "Removing container image soakhost ($(HCP_DSPACE)soakhost$(HCP_DTAG))"
	$Qdocker image rm $(HCP_DSPACE)soakhost$(HCP_DTAG)
	rm $(HCP_TESTS_OUT)/created.soakhost
endif
	rm -rf $(HCP_APPS_OUT)/soakhost
clean_tests: clean_soakhost
endif

##############
# Test cases #
##############

CREATED_CABOODLE := $(HCP_APPS_OUT)/created.caboodle
CREATED_CLIENT := $(HCP_APPS_OUT)/created.client
CREATED_SERVICES := $(foreach i,enroll attest swtpm,$(HCP_APPS_OUT)/created.$isvc)
CREATED_SOAKHOST := $(HCP_TESTS_OUT)/created.soakhost

# test_caboodle
test_caboodle: $(CREATED_CABOODLE)
test_caboodle:
	$Qecho "Starting caboodle test"
	$Qdocker run -it --rm $(HCP_DSPACE)caboodle$(HCP_DTAG) /hcp/caboodle/test.sh
	$Qecho "Successful completion of caboodle test"
TESTS += test_caboodle

# test_services (TODO: generalize exec-soak.sh for this too)
test_services: $(CREATED_SERVICES)
test_services: $(CREATED_CLIENT)
test_services: $(HCP_CREDS_DONE)
test_services:
	$Qecho "Starting services test"
	$Qdocker-compose up -d \
		enrollsvc_mgmt enrollsvc_repl \
		attestsvc_repl attestsvc_hcp \
		swtpmsvc
	$Qdocker-compose up client
	$Qdocker-compose down -v
	$Qecho "Successful completion of services test"
TESTS += test_services

# test_enrollsvc_soak
test_enrollsvc_soak: $(CREATED_SERVICES)
test_enrollsvc_soak: $(CREATED_SOAKHOST)
test_enrollsvc_soak: $(HCP_CREDS_DONE)
test_enrollsvc_soak:
	$Qecho "Starting enrollsvc_soak"
	$Qcd $(HCP_TESTS_SRC) && MANUAL=$(MANUAL) ./exec-soak.sh
	$Qecho "Successful completion of enrollsvc_soak"

###########
# Wrapper #
###########

tests: $(TESTS)

ifneq (,$(wildcard $(HCP_TESTS_OUT)))
clean_tests:
	$Qrmdir $(HCP_TESTS_OUT)
clean: clean_tests
endif
