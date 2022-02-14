HCP_SAFEBOOT_OUT := $(HCP_OUT)/safeboot
HCP_SAFEBOOT_SRC := $(TOP)/ext-safeboot

$(HCP_SAFEBOOT_OUT): | $(HCP_OUT)
MDIRS += $(HCP_SAFEBOOT_OUT)

HCP_SAFEBOOT_INSTALL := $(HCP_DSPACE)safeboot
HCP_SAFEBOOT_INSTALL_TOUCH := $(HCP_SAFEBOOT_OUT)/vol.created
$(HCP_SAFEBOOT_INSTALL_TOUCH): | $(HCP_SAFEBOOT_OUT)
	$Qdocker volume create $(HCP_SAFEBOOT_INSTALL)
	$Qtouch $@

HCP_SAFEBOOT_INSTALL_DEST := /safeboot

HCP_SAFEBOOT_DOCKER_RUN := \
	docker run -i --rm --label $(HCP_DSPACE)all=1 \
	--mount type=volume,source=$(HCP_SAFEBOOT_INSTALL),destination=$(HCP_SAFEBOOT_INSTALL_DEST) \
	--mount type=bind,source=$(HCP_SAFEBOOT_SRC),destination=/source,ro=true \
	$(HCP_BASE_DNAME) \
	bash -c

###################
# generic routine #
###################

HCP_SAFEBOOT_SUBSETS :=

# function safeboot_subset()
# $1 = name
# $2 = path relative to /safeboot, include leading and trailing "/"
# $3 = attributes (first arg to "chmod")
# $4 = source filenames
define safeboot_subset
$(eval tmp_CMD := mkdir -p $(HCP_SAFEBOOT_INSTALL_DEST)$2 ;)
$(eval tmp_CMD += cd $(HCP_SAFEBOOT_INSTALL_DEST)$2 ;)
$(eval tmp_CMD += $(foreach i,$4,cp /source$2$i ./ ; chmod $3 $i ;))

$(HCP_SAFEBOOT_OUT)/$1: | $(HCP_SAFEBOOT_INSTALL_TOUCH)
$(HCP_SAFEBOOT_OUT)/$1: $(HCP_BASE_TOUCHFILE)
$(HCP_SAFEBOOT_OUT)/$1: $(foreach i,$4,$(HCP_SAFEBOOT_SRC)$2$i)
	$Q$(HCP_SAFEBOOT_DOCKER_RUN) "$(tmp_CMD)"
	$Qtouch $$@

$(eval HCP_SAFEBOOT_SUBSETS += $1)
endef

$(eval $(call safeboot_subset,sb.root,/,644,functions.sh safeboot.conf))
$(eval $(call safeboot_subset,sb.sbin,/sbin/,755,$(shell ls -1 $(HCP_SAFEBOOT_SRC)/sbin)))
$(eval $(call safeboot_subset,sb.tests,/tests/,755,$(shell ls -1 $(HCP_SAFEBOOT_SRC)/tests)))
$(eval $(call safeboot_subset,sb.initramfs,/initramfs/,755,\
		bootscript \
		busybox.config \
		cmdline.txt \
		config.sh \
		dev.cpio \
		files.txt \
		init \
		linux.config \
		udhcpc.sh))

###################
# safeboot.tar.gz #
###################

HCP_SAFEBOOT_INSTALL_RUN := \
	docker run -i --rm --label $(HCP_DSPACE)all=1 \
	--mount type=volume,source=$(HCP_SAFEBOOT_INSTALL),destination=$(HCP_SAFEBOOT_INSTALL_DEST) \
	--mount type=bind,source=$(HCP_SAFEBOOT_OUT),destination=/put_it_here \
	$(HCP_BASE_DNAME) \
	bash -c

HCP_SAFEBOOT_INSTALL_CMD := cd /put_it_here ;
HCP_SAFEBOOT_INSTALL_CMD += tar zcf safeboot.tar.gz $(HCP_SAFEBOOT_INSTALL_DEST) ;
HCP_SAFEBOOT_INSTALL_CMD += /hcp/base/chowner.sh sb.root safeboot.tar.gz

$(HCP_SAFEBOOT_OUT)/safeboot.tar.gz: $(foreach i,$(HCP_SAFEBOOT_SUBSETS),$(HCP_SAFEBOOT_OUT)/$i)
$(HCP_SAFEBOOT_OUT)/safeboot.tar.gz:
	$Q$(HCP_SAFEBOOT_INSTALL_RUN) "$(HCP_SAFEBOOT_INSTALL_CMD)"

# A wrapper target to package safeboot
safeboot: $(HCP_SAFEBOOT_OUT)/safeboot.tar.gz
ALL += safeboot

# Cleanup
ifneq (,$(wildcard $(HCP_SAFEBOOT_OUT)))
clean_safeboot:
	$Qrm -f $(HCP_SAFEBOOT_OUT)/safeboot.tar.gz
ifneq (,$(wildcard $(HCP_SAFEBOOT_INSTALL_TOUCH)))
	$Qdocker volume rm $(HCP_SAFEBOOT_INSTALL)
	$Qrm $(HCP_SAFEBOOT_INSTALL_TOUCH)
endif
	$Qrm -rf $(HCP_SAFEBOOT_OUT)/sb.*
	$Qrmdir $(HCP_SAFEBOOT_OUT)
# Cleanup ordering
clean: clean_safeboot
endif
