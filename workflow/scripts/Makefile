HCP_SCRIPTS_OUT := $(HCP_OUT)/scripts

$(HCP_SCRIPTS_OUT): | $(HCP_OUT)
MDIRS += $(HCP_SCRIPTS_OUT)

# $1 = target that this script defines a rule for. E.g. sb.root, sb.sbin, sb.tests, sb.initramfs,
#       hcp.enrollsvc, etc.
define scripts_target_add
$(HCP_SCRIPTS_OUT)/$1: | $(HCP_SCRIPTS_OUT)
$(HCP_SCRIPTS_OUT)/$1:
	$Qtouch $$@
endef

# $1 = target registered via scripts_target_add
# $2 = destination path for the file, relative to the root. (For the root dir,
#      use ".") MDIR rules for the destination directory must exist.
# $3 = absolute source path for the file, not including the file name.
# $4 = file name.
# $5 = octal mode (as per chmod)
define scripts_add
$(HCP_SCRIPTS_OUT)/$1: $(HCP_SCRIPTS_OUT)/$2/$4
$(HCP_SCRIPTS_OUT)/$2/$4: | $(HCP_SCRIPTS_OUT)/$2
$(HCP_SCRIPTS_OUT)/$2/$4: $3/$4
	$Qcp $$< $$@.tmp
	$Qchmod $5 $$@.tmp
	$Qmv $$@.tmp $$@
endef

######################################
# safeboot scripts - safeboot.tar.gz #
######################################

# Two destination directories; /safeboot, /safeboot/sbin
HCP_SCRIPTS_SB_ROOT      := $(HCP_SCRIPTS_OUT)/safeboot
HCP_SCRIPTS_SB_SBIN      := $(HCP_SCRIPTS_SB_ROOT)/sbin
HCP_SCRIPTS_SB_TESTS     := $(HCP_SCRIPTS_SB_ROOT)/tests
HCP_SCRIPTS_SB_INITRAMFS := $(HCP_SCRIPTS_SB_ROOT)/initramfs
$(HCP_SCRIPTS_SB_ROOT):      | $(HCP_SCRIPTS_OUT)
$(HCP_SCRIPTS_SB_SBIN):      | $(HCP_SCRIPTS_SB_ROOT)
$(HCP_SCRIPTS_SB_TESTS):     | $(HCP_SCRIPTS_SB_ROOT)
$(HCP_SCRIPTS_SB_INITRAMFS): | $(HCP_SCRIPTS_SB_ROOT)
MDIRS += $(HCP_SCRIPTS_SB_ROOT)
MDIRS += $(HCP_SCRIPTS_SB_SBIN)
MDIRS += $(HCP_SCRIPTS_SB_TESTS)
MDIRS += $(HCP_SCRIPTS_SB_INITRAMFS)

# files for /safeboot
HCP_SCRIPTS_SB_ROOT_FILES := functions.sh safeboot.conf
$(eval $(call scripts_target_add,sb.root))
$(foreach i,$(HCP_SCRIPTS_SB_ROOT_FILES),\
	$(eval $(call scripts_add,sb.root,safeboot,$(TOP),$i,644)))

# files for /safeboot/sbin
HCP_SCRIPTS_SB_SBIN_FILES := $(shell ls -1 $(TOP)/sbin)
$(eval $(call scripts_target_add,sb.sbin))
$(foreach i,$(HCP_SCRIPTS_SB_SBIN_FILES),\
	$(eval $(call scripts_add,sb.sbin,safeboot/sbin,$(TOP)/sbin,$i,755)))

# files for /safeboot/tests
HCP_SCRIPTS_SB_TESTS_FILES := $(shell ls -1 $(TOP)/tests)
$(eval $(call scripts_target_add,sb.tests))
$(foreach i,$(HCP_SCRIPTS_SB_TESTS_FILES),\
	$(eval $(call scripts_add,sb.tests,safeboot/tests,$(TOP)/tests,$i,755)))

# files for /safeboot/initramfs
HCP_SCRIPTS_SB_INITRAMFS_FILES := bootscript		\
				  busybox.config	\
				  cmdline.txt		\
				  config.sh		\
				  dev.cpio		\
				  files.txt		\
				  init			\
				  linux.config		\
				  udhcpc.sh

$(eval $(call scripts_target_add,sb.initramfs))
$(foreach i,$(HCP_SCRIPTS_SB_INITRAMFS_FILES),\
	$(eval $(call scripts_add,sb.initramfs,safeboot/initramfs,$(TOP)/initramfs,$i,755)))

# safeboot.tar.gz
$(HCP_SCRIPTS_OUT)/safeboot.tar.gz: $(HCP_SCRIPTS_OUT)/sb.root
$(HCP_SCRIPTS_OUT)/safeboot.tar.gz: $(HCP_SCRIPTS_OUT)/sb.sbin
$(HCP_SCRIPTS_OUT)/safeboot.tar.gz: $(HCP_SCRIPTS_OUT)/sb.tests
$(HCP_SCRIPTS_OUT)/safeboot.tar.gz: $(HCP_SCRIPTS_OUT)/sb.initramfs
$(HCP_SCRIPTS_OUT)/safeboot.tar.gz:
	$Qtar zcf $(HCP_SCRIPTS_OUT)/safeboot.tar.gz \
		--owner root:0 --group root:0 -C $(HCP_SCRIPTS_OUT) safeboot
$(HCP_SCRIPTS_OUT)/safeboot.tar.gz.inject: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz
	$Qecho "$(call tarball_extract,safeboot)" > $@

################################
# HCP scripts - hcp-<x>.tar.gz #
################################

HCP_SCRIPTS_HCP_ROOT := $(HCP_SCRIPTS_OUT)/hcp
HCP_SCRIPTS_HCP_ENROLLSVC := $(HCP_SCRIPTS_HCP_ROOT)/enrollsvc
HCP_SCRIPTS_HCP_ATTESTSVC := $(HCP_SCRIPTS_HCP_ROOT)/attestsvc
HCP_SCRIPTS_HCP_SWTPMSVC := $(HCP_SCRIPTS_HCP_ROOT)/swtpmsvc
HCP_SCRIPTS_HCP_CLIENT := $(HCP_SCRIPTS_HCP_ROOT)/client
HCP_SCRIPTS_HCP_CABOODLE := $(HCP_SCRIPTS_HCP_ROOT)/caboodle
$(HCP_SCRIPTS_HCP_ROOT): | $(HCP_SCRIPTS_OUT)
$(HCP_SCRIPTS_HCP_ENROLLSVC): | $(HCP_SCRIPTS_HCP_ROOT)
$(HCP_SCRIPTS_HCP_ATTESTSVC): | $(HCP_SCRIPTS_HCP_ROOT)
$(HCP_SCRIPTS_HCP_SWTPMSVC): | $(HCP_SCRIPTS_HCP_ROOT)
$(HCP_SCRIPTS_HCP_CLIENT): | $(HCP_SCRIPTS_HCP_ROOT)
$(HCP_SCRIPTS_HCP_CABOODLE): | $(HCP_SCRIPTS_HCP_ROOT)
MDIRS += $(HCP_SCRIPTS_HCP_ROOT) $(HCP_SCRIPTS_HCP_ENROLLSVC) \
	$(HCP_SCRIPTS_HCP_ATTESTSVC) $(HCP_SCRIPTS_HCP_SWTPMSVC) \
	$(HCP_SCRIPTS_HCP_CLIENT) $(HCP_SCRIPTS_HCP_CABOODLE)

# /hcp (currently just to provide tail_wait.pl)
$(eval $(call scripts_target_add,hcp.common))
$(eval $(call scripts_add,hcp.common,hcp,$(TOP)/hcp,tail_wait.pl,755))

$(HCP_SCRIPTS_OUT)/hcp-common.tar.gz: $(HCP_SCRIPTS_OUT)/hcp.common
$(HCP_SCRIPTS_OUT)/hcp-common.tar.gz:
	$Qtar zcf $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz \
		--owner root:0 --group root:0 -C $(HCP_SCRIPTS_OUT) hcp/tail_wait.pl
$(HCP_SCRIPTS_OUT)/hcp-common.tar.gz.inject: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz
	$Qecho "$(call tarball_extract,hcp-common)" > $@

# /hcp/enrollsvc
HCP_SCRIPTS_HCP_ENROLLSVC_FILES = $(shell ls -1 $(TOP)/hcp/enrollsvc | \
				grep -v Makefile | egrep -v ".*.Dockerfile")
$(eval $(call scripts_target_add,hcp.enrollsvc))
$(foreach i,$(HCP_SCRIPTS_HCP_ENROLLSVC_FILES),\
	$(eval $(call scripts_add,hcp.enrollsvc,hcp/enrollsvc,\
		$(TOP)/hcp/enrollsvc,$i,755)))

$(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz: $(HCP_SCRIPTS_OUT)/hcp.enrollsvc
$(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz:
	$Qtar zcf $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz \
		--owner root:0 --group root:0 -C $(HCP_SCRIPTS_OUT) hcp/enrollsvc
$(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz.inject: $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz
	$Qecho "$(call tarball_extract,hcp-enrollsvc)" > $@

# files for /hcp/attestsvc
HCP_SCRIPTS_HCP_ATTESTSVC_FILES = $(shell ls -1 $(TOP)/hcp/attestsvc | \
				grep -v Makefile | egrep -v ".*.Dockerfile")
$(eval $(call scripts_target_add,hcp.attestsvc))
$(foreach i,$(HCP_SCRIPTS_HCP_ATTESTSVC_FILES),\
	$(eval $(call scripts_add,hcp.attestsvc,hcp/attestsvc,\
		$(TOP)/hcp/attestsvc,$i,755)))

$(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz: $(HCP_SCRIPTS_OUT)/hcp.attestsvc
$(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz:
	$Qtar zcf $(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz \
		--owner root:0 --group root:0 -C $(HCP_SCRIPTS_OUT) hcp/attestsvc
$(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz.inject: $(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz
	$Qecho "$(call tarball_extract,hcp-attestsvc)" > $@

# files for /hcp/swtpmsvc
HCP_SCRIPTS_HCP_SWTPMSVC_FILES = $(shell ls -1 $(TOP)/hcp/swtpmsvc | \
				grep -v Makefile | egrep -v ".*.Dockerfile")
$(eval $(call scripts_target_add,hcp.swtpmsvc))
$(foreach i,$(HCP_SCRIPTS_HCP_SWTPMSVC_FILES),\
	$(eval $(call scripts_add,hcp.swtpmsvc,hcp/swtpmsvc,\
		$(TOP)/hcp/swtpmsvc,$i,755)))
$(eval $(call scripts_add,hcp.swtpmsvc,hcp/swtpmsvc,\
	$(TOP)/hcp/python,enroll_api.py,755))

$(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz: $(HCP_SCRIPTS_OUT)/hcp.swtpmsvc
$(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz:
	$Qtar zcf $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz \
		--owner root:0 --group root:0 -C $(HCP_SCRIPTS_OUT) hcp/swtpmsvc
$(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz.inject: $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz
	$Qecho "$(call tarball_extract,hcp-swtpmsvc)" > $@

# files for /hcp/client
HCP_SCRIPTS_HCP_CLIENT_FILES = $(shell ls -1 $(TOP)/hcp/client | \
				grep -v Makefile | egrep -v ".*.Dockerfile")
$(eval $(call scripts_target_add,hcp.client))
$(foreach i,$(HCP_SCRIPTS_HCP_CLIENT_FILES),\
	$(eval $(call scripts_add,hcp.client,hcp/client,\
		$(TOP)/hcp/client,$i,755)))

$(HCP_SCRIPTS_OUT)/hcp-client.tar.gz: $(HCP_SCRIPTS_OUT)/hcp.client
$(HCP_SCRIPTS_OUT)/hcp-client.tar.gz:
	$Qtar zcf $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz \
		--owner root:0 --group root:0 -C $(HCP_SCRIPTS_OUT) hcp/client
$(HCP_SCRIPTS_OUT)/hcp-client.tar.gz.inject: $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz
	$Qecho "$(call tarball_extract,hcp-client)" > $@

# files for /hcp/caboodle
HCP_SCRIPTS_HCP_CABOODLE_FILES = $(shell ls -1 $(TOP)/hcp/caboodle | \
				grep -v Makefile | egrep -v ".*.Dockerfile")
$(eval $(call scripts_target_add,hcp.caboodle))
$(foreach i,$(HCP_SCRIPTS_HCP_CABOODLE_FILES),\
	$(eval $(call scripts_add,hcp.caboodle,hcp/caboodle,\
		$(TOP)/hcp/caboodle,$i,755)))

$(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz: $(HCP_SCRIPTS_OUT)/hcp.caboodle
$(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz:
	$Qtar zcf $(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz \
		--owner root:0 --group root:0 -C $(HCP_SCRIPTS_OUT) hcp/caboodle
$(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz.inject: $(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz
	$Qecho "$(call tarball_extract,hcp-caboodle)" > $@


###################
# wrapper targets #
###################

hcp_scripts: $(HCP_SCRIPTS_OUT)/safeboot.tar.gz
hcp_scripts: $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz
hcp_scripts: $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz
hcp_scripts: $(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz
hcp_scripts: $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz
hcp_scripts: $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz
hcp_scripts: $(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz

clean_hcp_scripts:
	$Qrm -f $(HCP_SCRIPTS_OUT)/safeboot.tar.gz
	$Qrm -f $(HCP_SCRIPTS_OUT)/hcp-common.tar.gz
	$Qrm -f $(HCP_SCRIPTS_OUT)/hcp-enrollsvc.tar.gz
	$Qrm -f $(HCP_SCRIPTS_OUT)/hcp-attestsvc.tar.gz
	$Qrm -f $(HCP_SCRIPTS_OUT)/hcp-swtpmsvc.tar.gz
	$Qrm -f $(HCP_SCRIPTS_OUT)/hcp-client.tar.gz
	$Qrm -f $(HCP_SCRIPTS_OUT)/hcp-caboodle.tar.gz
	$Qrm -rf $(HCP_SCRIPTS_OUT)

# Cleanup ordering
clean_hcp: clean_hcp_scripts
