#!/bin/bash

# This caboodle-specific 'hcp.sh' is expected to be a superset of the common
# 'hcp.sh', so source that before we move on.
source /hcp/common/hcp.sh

# Managing services within a caboodle container

declare -A hcp_services=( \
	[enrollsvc_mgmt]=/hcp/enrollsvc/run_mgmt.sh \
	[enrollsvc_repl]=/hcp/enrollsvc/run_repl.sh \
	[attestsvc_repl]=/hcp/attestsvc/run_repl.sh \
	[attestsvc_hcp]=/hcp/attestsvc/run_hcp.sh \
	[swtpmsvc]=/hcp/swtpmsvc/run_swtpm.sh )

function hcp_service_is_specified {
	[[ -z $1 ]] &&
		echo "Error, HCP service not specified. Choose from;" &&
		echo "    ${!hcp_services[@]}" &&
		return 1
	return 0
}

function hcp_service_is_valid {
	hcp_service_is_specified $1 || return 1
	cmd=${hcp_services[$1]}
	[[ -z $cmd ]] &&
		echo "Error, unrecognized HCP service: $1. Choose from;" &&
		echo "    ${!hcp_services[@]}" &&
		return 1
	return 0
}

function hcp_service_is_started {
	hcp_service_is_valid $1 || return 1
	pidfile=/pids/$1
	[[ -f $pidfile ]] && return 0
	return 1
}

function hcp_service_start {
	pidfile=/pids/$1
	logfile=/logs/$1
	hcp_service_is_valid $1 || return 1
	if hcp_service_is_started $1; then
		echo "Error, HCP service $1 already has a PID file ($pidfile)"
		return 1
	fi
	${hcp_services[$1]} > $logfile 2>&1 &
	echo $! > $pidfile
	echo "Started HCP service $1 (PID=$(cat $pidfile))"
}

function hcp_service_stop {
	pidfile=/pids/$1
	hcp_service_is_valid $1 || return 1
	if ! hcp_service_is_started $1; then
		echo "Error, HCP service $1 has no PID file ($pidfile)"
		return 1
	fi
	pid=$(cat $pidfile) &&
		kill -TERM $pid &&
		rm $pidfile ||
		(
			echo "Error, stopping HCP service $1 ($pidfile,$pid)"
			exit 1
		) || return 1
	echo "Stopped HCP service $1"
}

function hcp_service_alive {
	hcp_service_is_valid $1 || return 1
	hcp_service_is_started $1 || return 1
	pidfile=/pids/$1
	pid=$(cat $pidfile)
	if ! kill -0 $pid > /dev/null 2>&1; then
		return 1
	fi
	return 0
}

function hcp_services_start {
	echo "Starting all HCP services"
	for key in "${!hcp_services[@]}"; do
		if hcp_service_is_started $key; then
			echo "Skipping $key, already started"
		else
			hcp_service_start $key || return 1
		fi
	done
}

function hcp_services_stop {
	echo "Stopping all HCP services"
	for key in "${!hcp_services[@]}"; do
		if ! hcp_service_is_started $key; then
			echo "Skipping $key, not started"
		else
			hcp_service_stop $key || return 1
		fi
	done
}

function hcp_services_all_started {
	for key in "${!hcp_services[@]}"; do
		if ! hcp_service_is_started $key; then
			return 1
		fi
	done
	return 0
}

function hcp_services_any_started {
	for key in "${!hcp_services[@]}"; do
		if hcp_service_is_started $key; then
			return 0
		fi
	done
	return 1
}

function hcp_services_status {
	echo "HCP services status;"
	for key in "${!hcp_services[@]}"; do
		echo -n "$key: "
		if hcp_service_is_started $key; then
			if hcp_service_alive $key; then
				echo "started"
			else
				echo "FAILED"
			fi
		else
			echo "no started"
		fi
	done
}
