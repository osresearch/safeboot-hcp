HCP_TESTS_SRC := $(TOP)/tests

CREATED_CABOODLE := $(HCP_APPS_OUT)/created.caboodle
CREATED_CLIENT := $(HCP_APPS_OUT)/created.client
CREATED_SERVICES := $(foreach i,enroll attest swtpm,\
			$(HCP_APPS_OUT)/created.$isvc)

# We need a unique ID that can be passed to docker-compose via the '-p'
# flag, to ensure that any and all containers (and networks) that get
# started up are isolated from anything else that may have been running
# or that may get run later.
TESTUID=$(shell date +p_%s_%N)
DCOMPOSE="docker-compose --project-name $(TESTUID)"

define test_case
$(eval name := $(strip $1))
$(eval deps := $(strip $2))
test_$(name): $(foreach i,$(deps),$(CREATED_$i))
test_$(name):
	$Qecho "Starting '$$@'"
	$QDCOMPOSE=$(DCOMPOSE) bash $(HCP_TESTS_SRC)/$(name).sh
	$Qecho "Successful completion of '$$@'"
$(eval TESTS += test_$(name))
endef

$(eval $(call test_case,caboodle_alone_basic,CABOODLE))
$(eval $(call test_case,services_client_basic,CLIENT SERVICES))
$(eval $(call test_case,services_soak_basic,CABOODLE SERVICES))
$(eval $(call test_case,services_soak_persist,CABOODLE SERVICES))

tests: $(TESTS)
