#!/bin/bash

# This is the dev-host-side script that starts up the containers to run the
# soakhost test. The point is to always shut everything down, even (especially)
# if the test failed.

function trapper {
	docker-compose down
}
trap trapper EXIT ERR

docker-compose up -d \
	enrollsvc_mgmt enrollsvc_repl \
	attestsvc_repl attestsvc_hcp

if [[ -n $MANUAL ]]; then
	docker-compose run --rm soakhost_manual
else
	docker-compose up soakhost
fi
