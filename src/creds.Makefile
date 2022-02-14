HCP_CREDS_OUT := $(HCP_OUT)/creds

$(HCP_CREDS_OUT): | $(HCP_OUT)
MDIRS += $(HCP_CREDS_OUT)

HCP_CREDS_DOCKER_RUN := \
	docker run -i --rm --label $(HCP_DSPACE)all=1 \
	--mount type=bind,source=$(HCP_CREDS_OUT),destination=/creds \
	$(HCP_BASE_DNAME) \
	bash -c

# A pre-requisite for all assets is the "reference" file. This gets used as the
# "--reference" argument to chown commands, to ensure that all files created
# within the containers have the expected file-system ownership on the
# host-side. It also, encapsulates the dependency on $(HCP_OUT) being created.
$(HCP_CREDS_OUT)/reference: | $(HCP_OUT)
	$Qecho "Unused file" > "$@"

CMD_CREDS_CHOWN := /hcp/base/chowner.sh /creds/reference .

# "enrollsig"
HCP_CREDS_ENROLLSIG := $(HCP_CREDS_OUT)/enrollsig
$(HCP_CREDS_ENROLLSIG): | $(HCP_CREDS_OUT)
MDIRS += $(HCP_CREDS_ENROLLSIG)
CMD_CREDS_ENROLLSIG := cd /creds/enrollsig &&
CMD_CREDS_ENROLLSIG += openssl genrsa -out key.priv &&
CMD_CREDS_ENROLLSIG += openssl rsa -pubout -in key.priv -out key.pem &&
CMD_CREDS_ENROLLSIG += $(CMD_CREDS_CHOWN)
$(HCP_CREDS_OUT)/done.enrollsig: | $(HCP_CREDS_ENROLLSIG)
$(HCP_CREDS_OUT)/done.enrollsig: $(HCP_CREDS_OUT)/reference
$(HCP_CREDS_OUT)/done.enrollsig:
	$Q$(HCP_CREDS_DOCKER_RUN) "$(CMD_CREDS_ENROLLSIG)"
	$Qtouch $@
HCP_CREDS_DONE += $(HCP_CREDS_OUT)/done.enrollsig

# "enrollverif" - this is simply the public-only half of enrollsig
HCP_CREDS_ENROLLVERIF := $(HCP_CREDS_OUT)/enrollverif
$(HCP_CREDS_ENROLLVERIF): | $(HCP_CREDS_OUT)
MDIRS += $(HCP_CREDS_ENROLLVERIF)
$(HCP_CREDS_OUT)/done.enrollverif: | $(HCP_CREDS_ENROLLVERIF)
$(HCP_CREDS_OUT)/done.enrollverif: $(HCP_CREDS_OUT)/done.enrollsig
$(HCP_CREDS_OUT)/done.enrollverif:
	$Qcp $(HCP_CREDS_ENROLLSIG)/key.pem $(HCP_CREDS_ENROLLVERIF)/
	$Qtouch $@
HCP_CREDS_DONE += $(HCP_CREDS_OUT)/done.enrollverif

# "enrollca"
HCP_CREDS_ENROLLCA := $(HCP_CREDS_OUT)/enrollca
$(HCP_CREDS_ENROLLCA): | $(HCP_CREDS_OUT)
MDIRS += $(HCP_CREDS_ENROLLCA)
CMD_CREDS_ENROLLCA := cd /creds/enrollca &&
CMD_CREDS_ENROLLCA += openssl genrsa -out CA.priv &&
CMD_CREDS_ENROLLCA += openssl req -new -key CA.priv -subj /CN=localhost -x509 -out CA.cert &&
CMD_CREDS_ENROLLCA += $(CMD_CREDS_CHOWN)
$(HCP_CREDS_OUT)/done.enrollca: | $(HCP_CREDS_ENROLLCA)
$(HCP_CREDS_OUT)/done.enrollca: $(HCP_CREDS_OUT)/reference
$(HCP_CREDS_OUT)/done.enrollca:
	$Q$(HCP_CREDS_DOCKER_RUN) "$(CMD_CREDS_ENROLLCA)"
	$Qtouch $@
HCP_CREDS_DONE += $(HCP_CREDS_OUT)/done.enrollca

# A wrapper target to package creds
creds: $(HCP_CREDS_OUT)/done.enrollsig
creds: $(HCP_CREDS_OUT)/done.enrollca
creds: $(HCP_CREDS_OUT)/done.enrollverif
ALL += creds

# Cleanup
ifneq (,$(wildcard $(HCP_CREDS_OUT)))
clean_creds:
	$Qrm -f $(HCP_CREDS_OUT)/reference
	$Qrm -rf $(HCP_CREDS_ENROLLSIG)
	$Qrm -rf $(HCP_CREDS_ENROLLCA)
	$Qrm -rf $(HCP_CREDS_ENROLLVERIF)
	$Qrm -f $(HCP_CREDS_DONE)
	$Qrmdir $(HCP_CREDS_OUT)
# Cleanup ordering
clean: clean_creds
endif
