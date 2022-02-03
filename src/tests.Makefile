# Caboodle test
test_caboodle: $(HCP_APPS_OUT)/created.caboodle
test_caboodle:
	$Qecho "Starting caboodle test"
	$Qdocker run -it --rm $(HCP_DSPACE)caboodle$(HCP_DTAG) /hcp/caboodle/test.sh
	$Qecho "Successful completion of caboodle test"
TESTS += test_caboodle

# Services test
test_services: $(HCP_APPS_OUT)/created.enrollsvc
test_services: $(HCP_APPS_OUT)/created.attestsvc
test_services: $(HCP_APPS_OUT)/created.swtpmsvc
test_services: $(HCP_APPS_OUT)/created.client
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

###########
# Wrapper #
###########

tests: $(TESTS)
