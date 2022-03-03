#!/bin/bash

set -e

test -f ${HCP_ATTESTSVC_STATE_PREFIX}/initialized &&
	test ! -f ${HCP_ATTESTSVC_STATE_PREFIX}/transient-failure
