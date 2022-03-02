#!/bin/bash

set -e

export PATH=/install/bin:/safeboot/sbin:$PATH
export LD_LIBRARY_PATH=/install/lib:$LD_LIBRARY_PATH
export DIR=/safeboot
cd $DIR

# Iteration utility. This allows you to do;
#     run_all n do_a_thing arg1 arg2
# and what will happen is;
#     do_a_thing 0 arg1 arg2
#     do_a_thing 1 arg1 arg2
#     [...]
#     do_a_thing <n-1> arg1 arg2
function run_all {
	local i=0
	local exitcode=0
	count=$1
	torun=$2
	shift
	shift
	until [[ $i -eq $count || $exitcode -ne 0 ]]; do
		$torun $((i++)) $@ || exitcode=$?
	done
	return $exitcode
}

#################################
# Handle a set of software TPMs #
#################################

[[ -z $SOAK_NUM_SWTPMS ]] &&
	echo "ERROR, set SOAK_NUM_SWTPMS" &&
	exit 1 ||
	true

# Where their state goes (including sockets)
BASE_SWTPM=/swtpm_base
mkdir -p $BASE_SWTPM

# The arrays for per-swtpm state
declare -a swtpm_log
declare -a swtpm_prefix
declare -a swtpm_socket
declare -a swtpm_hostname
declare -a swtpm_pid
declare -a swtpm_error
declare -a swtpm_lock
declare -a swtpm_enrolled
declare -a swtpm_ekpubhash

# Iterator
function swtpm_all {
	torun=$1
	shift
	run_all $SOAK_NUM_SWTPMS $torun $@
}

# Given a swtpm, calculate the ekpubhash, then query enrollsvc to see if it's
# enrolled.
function swtpm_query {
	ossl=$(openssl sha256 ${swtpm_prefix[$1]}/tpm/ek.pub)
	swtpm_ekpubhash[$1]=$(echo "$ossl" | sed -e "s/^.*= //" | cut -c 1-32)
	echo 0 > ${swtpm_enrolled[$1]}
	json=$(python3 /hcp/swtpmsvc/enroll_api.py --api $HCP_SWTPMSVC_ENROLL_API \
					query ${swtpm_ekpubhash[$1]})
	echo "$json" | jq -e '.entries|length>0' &&
		echo 1 > ${swtpm_enrolled[$1]} || true
}

# Open logs and do foregrounded setup for each swtpm
function swtpm_setup {
	swtpm_prefix[$1]=$BASE_SWTPM/$1
	swtpm_socket[$1]=$BASE_SWTPM/socket_$1
	swtpm_log[$1]=$BASE_SWTPM/log_$1
	swtpm_enrolled[$1]=$BASE_SWTPM/enrolled_$1
	swtpm_hostname[$1]=host$1.realm.example.xyz
	swtpm_pid[$1]=""
	swtpm_error[$1]=$BASE_SWTPM/error_$1
	swtpm_lock[$1]=$BASE_SWTPM/lock_$1
	local exitcode=0
	if [[ ! -f ${swtpm_prefix[$1]}/initialized ]]; then
		mkdir -p ${swtpm_prefix[$1]}
		# Run the setup
		echo -n "Creating swtpm $1 ... "
		export HCP_SWTPMSVC_STATE_PREFIX=${swtpm_prefix[$1]}
		export HCP_SOCKET=${swtpm_socket[$1]}
		export HCP_SWTPMSVC_ENROLL_HOSTNAME=${swtpm_hostname[$1]}
		/hcp/swtpmsvc/setup_swtpm.sh > ${swtpm_log[$1]} 2>&1 &&
				swtpm_query $1 >> ${swtpm_log[$1]} 2>&1 ||
			exitcode=$?
		[[ $exitcode -eq 0 ]] &&
			echo "SUCCESS" &&
			echo 1 > ${swtpm_enrolled[$1]} ||
			echo "FAILED"
	else
		echo -n "Existing swtpm $1 ... "
		swtpm_query $1 >> ${swtpm_log[$1]} 2>&1 &&
			exitcode=$?
		[[ $exitcode -eq 0 ]] &&
			echo -n "SUCCESS " &&
			(
				[[ $(cat ${swtpm_enrolled[$1]}) == "1" ]] &&
					echo "(enrolled)" ||
					echo "(not enrolled)"
			) ||
			echo "FAILED"
	fi
	[[ $exitcode -ne 0 ]] && touch ${swtpm_error[$1]}
	return $exitcode
}

# Background the swtpm and check that we can read its PCRs
function swtpm_start {
	echo -n "Starting swtpm $1 ... "
	export HCP_SWTPMSVC_STATE_PREFIX=${swtpm_prefix[$1]}
	export HCP_SOCKET=${swtpm_socket[$1]}
	export HCP_SWTPMSVC_ENROLL_HOSTNAME=${swtpm_hostname[$1]}
	/hcp/swtpmsvc/run_swtpm.sh > ${swtpm_log[$1]} 2>&1 &
	swtpm_pid[$1]=$!
	export TPM2TOOLS_TCTI=swtpm:path=$HCP_SOCKET
	local waitsecs=0
	local waitinc=1
	local waitcount=0
	local pcrread_log=$(mktemp)
	until tpm2_pcrread > $pcrread_log 2>&1; do
		if [[ $((++waitcount)) -eq 3 ]]; then
			echo "FAILED: TPM not available"
			echo "Dumping 'tpm2_pcrread' output;"
			cat $pcrread_log
			rm $pcrread_log
			touch ${swtpm_error[$1]}
			return 1
		fi
		sleep $((waitsecs+=waitinc))
	done
	echo "SUCCESS (pid=${swtpm_pid[$1]})"
	rm $pcrread_log
	# Sneaky hack, see corresponding note in
	# src/aps/client/run_client.sh
	tpm2_dictionarylockout --clear-lockout > /dev/null 2>&1 || true
}

# Signal the swtpm to exit
function swtpm_stop {
	kill ${swtpm_pid[$1]}
}

# Exit/error-handling
function swtpm_on_exit {
	[[ -f ${swtpm_error[$1]} ]] &&
		rm -f ${swtpm_error[$1]} &&
		[[ -f ${swtpm_log[$1]} ]] &&
		echo "Dumping swtpm $1 logfile" &&
		cat ${swtpm_log[$1]}
	[[ -f ${swtpm_log[$1]} ]] && rm -f ${swtpm_log[$1]}
	[[ -f ${swtpm_socket[$1]} ]] && rm -f ${swtpm_socket[$1]}*
#	[[ -f ${swtpm_prefix[$1]} ]] && rm -rf ${swtpm_prefix[$1]}
	[[ -d ${swtpm_lock[$1]} ]] && rmdir ${swtpm_lock[$1]}
	true
}

# Find an unused swtpm and lock it
function swtpm_get {
	local resultpath=$1
	i=$((SOAK_NUM_SWTPMS + 1))
	local retries=0
	until false; do
		i=$((SRANDOM % SOAK_NUM_SWTPMS))
		mkdir ${swtpm_lock[$i]} > /dev/null 2>&1 &&
			break
		if [[ $((++retries)) -eq 10 ]]; then
			exit 1
		fi
	done
	echo $i > $resultpath
}

# Corresponding unlock
function swtpm_put {
	rmdir ${swtpm_lock[$1]} > /dev/null 2>&1 &&
		return 0
	return 1
}

# Reap PIDs
function swtpm_remove {
	[[ ${swtpm_pid[$1]} -eq $2 ]] &&
		swtpm_pid[$1]="" ||
		true
}

########################################
# Handle a set of soak-testing workers #
########################################

# How many workers, and how many loops they run
[[ -z $SOAK_NUM_WORKERS ]] &&
	echo "ERROR, set SOAK_NUM_WORKERS" &&
	exit 1 ||
	true
[[ -z $SOAK_NUM_LOOPS ]] &&
	echo "ERROR, set SOAK_NUM_LOOPS" &&
	exit 1 ||
	true

if [[ $SOAK_NUM_SWTPMS -lt $SOAK_NUM_WORKERS ]]; then
	echo "Error, SOAK_NUM_SWTPMS ($SOAK_NUM_SWTPMS) < SOAK_NUM_WORKERS ($SOAK_NUM_WORKERS)"
	exit 1
fi

# Where their state goes
BASE_WORKER=/worker_base
mkdir -p $BASE_WORKER

# The arrays for per-worker state
declare -a worker_pid
declare -a worker_dir
declare -a worker_log
declare -a worker_swtpm
declare -a worker_secrets
declare -a worker_extracted
declare -a worker_error

# Iterator
function worker_all {
	torun=$1
	shift
	run_all $SOAK_NUM_WORKERS $torun $@
}

# A single item of work, within the worker_loop
function worker_item {
	# Find and lock one of the available SWTPMs
	swtpm_get ${worker_swtpm[$1]}
	idx=$(cat ${worker_swtpm[$1]})
	export TPM2TOOLS_TCTI=swtpm:path=${swtpm_socket[$idx]}
	# Choose what work we'll do. If the swtpm isn't enrolled, easy, we'll
	# enroll it. Otherwise, we will either unenroll it or attest, based on
	# SOAK_PC_ATTEST. "PC"=="PerCent", meaning if it's 0 then we always
	# unenroll, if it's 100, we always attest, and we can range between
	# those extremes.
	local failure=0
	if [[ $(cat ${swtpm_enrolled[$idx]}) == "0" ]]; then
		# Enroll
		if ! json=$(python3 /hcp/swtpmsvc/enroll_api.py \
					--api $HCP_SWTPMSVC_ENROLL_API \
					add \
					"${swtpm_prefix[$idx]}/tpm/ek.pub" \
					"${swtpm_hostname[$idx]}" 2>> \
						${worker_log[$1]}); then
			echo "FAILED: enrollsvc mgmt API 'add' (json=$json)"
			failure=1
		elif ! ret=$(echo "$json" | jq -r '.returncode' 2>> \
						${worker_log[$1]}); then
			echo "FAILED: enrollsvc mgmt API call (json=$json,ret=$ret)"
			failure=1
		elif [[ $ret != 0 ]]; then
			echo "ERROR: enrollment failed (ret=$ret)"
			failure=1
		else
			echo "worker $1: swtpm $idx: enrolled"
			echo 1 > ${swtpm_enrolled[$idx]}
		fi
	elif [[ $((SRANDOM % 100)) -lt $SOAK_PC_ATTEST ]]; then
		# Attest
		local waitsecs=0
		local waitinc=3
		local waitcount=0
		until ./sbin/tpm2-attest attest $HCP_CLIENT_ATTEST_URL \
					> ${worker_secrets[$1]} \
					2>> ${worker_log[$1]} ||
				[[ $failure -eq 1 ]];
		do
			if [[ $((++waitcount)) -eq 4 ]]; then
				echo "FAILED: attestation failed, worker $1"
				failure=1
			else
				sleep $((waitsecs+=waitinc))
			fi
		done
		if [[ $failure -eq 0 ]] && ! (cd ${worker_extracted[$1]} &&
					tar xf ${worker_secrets[$1]}); then
			echo "FAILED: attestation result wasn't a tarball"
			failure=1
		fi
		if [[ $failure -eq 0 ]] && ! ./sbin/tpm2-attest verify-unsealed \
					${worker_extracted[$1]} >> \
					${worker_log[$1]} 2>&1; then
			echo "FAILED: post-attestation verification failed"
			failure=1
		fi
		[[ $failure -eq 0 ]] &&
			echo "worker $1: swtpm $idx: attest" ||
			true
	else
		# Unenroll
		if ! json=$(python3 /hcp/swtpmsvc/enroll_api.py \
					--api $HCP_SWTPMSVC_ENROLL_API \
					delete \
					"${swtpm_ekpubhash[$idx]}" 2>> \
						${worker_log[$1]}); then
			echo "FAILED: enrollsvc mgmt API 'delete' (json=$json)"
			failure=1
		elif ! $(echo "$json" | jq -e '.entries|length>0' >> \
					${worker_log[$1]} 2>&1); then
			echo "ERROR: unenrollment failed (json=$json)"
			failure=1
		else
			echo "worker $1: swtpm $idx: unenrolled"
			echo 0 > ${swtpm_enrolled[$idx]}
		fi
	fi
	rm ${worker_swtpm[$1]}
	rm -f ${worker_secrets[$1]}
	rm -f ${worker_extracted[$1]}/*
	[[ $failure -eq 0 ]] && rm -f ${worker_log[$1]} ||
		echo "FAILURE in worker $1 using swtpm $idx"
	swtpm_put $idx
	return $failure
}

# The (backgrounded) worker loop
function worker_loop {
	sleep 1
	local loops=0
	local failure=0
	until [[ $loops -eq $SOAK_NUM_LOOPS || $failure -ne 0 ]]; do
		worker_item $1 || failure=1
		loops=$((loops + 1))
	done
	[[ $failure -ne 0 ]] &&
		touch ${worker_error[$1]} &&
		return 1
	return 0
}

# Launch (background) each worker
function worker_launch {
	echo -n "Starting worker $1 ... "
	# per-worker variables, all but 'pid' are filesystem paths
	worker_pid[$1]=""
	worker_dir[$1]=$BASE_WORKER/$1
	mkdir -p ${worker_dir[$1]}
	worker_log[$1]=${worker_dir[$1]}/log
	worker_swtpm[$1]=${worker_dir[$1]}/current_swtpm
	worker_secrets[$1]=${worker_dir[$1]}/secrets
	worker_extracted[$1]=${worker_dir[$1]}/extracted
	mkdir -p ${worker_extracted[$1]}
	worker_error[$1]=${worker_dir[$1]}/ERROR_BLOCK
	worker_loop $1 2> ${worker_log[$1]} &
	worker_pid[$1]=$!
	echo "STARTED (pid=${worker_pid[$1]})"
}

# Exit/error handling
# We only use "rm -rf" for the 'extracted' dir, because we can't know and
# don't care what's in there. But for everything else, files are "rm" (no
# "-f") and directories are "rmdir" (not "rm -rf"). If something goes wrong
# (or if the code goes stale), we don't want an aggressive destructor
# hiding it.
function worker_on_exit {
	[[ -f ${worker_error[$1]} ]] &&
		rm ${worker_error[$1]} &&
		[[ -f ${worker_log[$1]} ]] &&
		echo "Dumping worker $1 logfile" &&
		cat ${worker_log[$1]}
	[[ -f ${worker_log[$1]} ]] && rm ${worker_log[$1]}
	[[ -f ${worker_swtpm[$1]} ]] && rm ${worker_swtpm[$1]}
	[[ -f ${worker_secrets[$1]} ]] && rm ${worker_secrets[$1]}
	[[ -d ${worker_extracted[$1]} ]] && rm -rf ${worker_extracted[$1]}
	[[ -d ${worker_dir[$1]} ]] && rmdir ${worker_dir[$1]}
	true
}

# Reap PIDs
function worker_remove {
	[[ ${worker_pid[$1]} -eq $2 ]] &&
		worker_pid[$1]="" ||
		true
}

#############################
# Now, the "main()" code... #
#############################

function exit_trapper {
	swtpm_all swtpm_on_exit
	worker_all worker_on_exit
}
trap exit_trapper EXIT ERR

echo "Setting up software TPMs"
swtpm_all swtpm_setup || exit 1

echo "Starting software TPMs"
swtpm_all swtpm_start || exit 1

echo "Starting software workers"
worker_all worker_launch || exit 1

echo "Waiting for workers to exit"
reaped=0
total_failure=0
until [[ $reaped -eq SOAK_NUM_WORKERS || $failure -ne 0 ]]; do
	failure=0
	wait -n -p dead_pid ${worker_pid[@]} || failure=1
	[[ $failure -ne 0 ]] &&
		total_failure=$((total_failure+1)) || true
	reaped=$((reaped+1))
	worker_all worker_remove $dead_pid
done
[[ $total_failure -ne 0 ]] &&
	echo "FAILURE" &&
	exit 1

echo "Stopping software TPMs"
swtpm_all swtpm_stop || exit 1

echo "Waiting for software TPMs to exit"
reaped=0
until [[ $reaped -eq SOAK_NUM_SWTPMS || $failure -ne 0 ]]; do
	wait -n -p dead_pid ${swtpm_pid[@]} || true
	reaped=$((reaped+1))
	swtpm_all swtpm_remove $dead_pid
done

echo "SUCCESS"
