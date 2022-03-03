#!/bin/bash

function show_hcp_env {
	printenv | egrep -e "^HCP_" | sort
}

function export_hcp_env {
	printenv | egrep -e "^HCP_" | sort | sed -e "s/^HCP_/export HCP_/"
}
