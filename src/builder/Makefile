HCP_BUILDER_SRC := $(HCP_SRC)/builder
HCP_BUILDER_OUT := $(HCP_OUT)/builder
HCP_BUILDER_DNAME := $(HCP_DSPACE)builder$(HCP_DTAG)

$(HCP_BUILDER_OUT): | $(HCP_OUT)
MDIRS += $(HCP_BUILDER_OUT)

# A wrapper target to build the "builder" image
builder: $(HCP_BUILDER_OUT)/built
ALL += builder

$(HCP_BUILDER_OUT)/git: | $(HCP_BUILDER_OUT)
$(HCP_BUILDER_OUT)/git: $(HCP_BUILDER_SRC)/git
	$Qcp $< $@

$(HCP_BUILDER_OUT)/Dockerfile: | $(HCP_BUILDER_OUT)
$(HCP_BUILDER_OUT)/Dockerfile: $(HCP_BUILDER_SRC)/Makefile
$(HCP_BUILDER_OUT)/Dockerfile: $(HCP_BUILDER_SRC)/Dockerfile
$(HCP_BUILDER_OUT)/Dockerfile:
	$Qecho "FROM $(HCP_BASE_DNAME)" > $@
	$Qcat $(HCP_BUILDER_SRC)/Dockerfile >> $@

$(HCP_BUILDER_OUT)/built: $(HCP_BUILDER_OUT)/Dockerfile
$(HCP_BUILDER_OUT)/built: $(HCP_BASE_TOUCHFILE)
$(HCP_BUILDER_OUT)/built: $(HCP_BUILDER_OUT)/git
$(HCP_BUILDER_OUT)/built:
	$Qdocker build -t $(HCP_BUILDER_DNAME) \
	               -f $(HCP_BUILDER_OUT)/Dockerfile \
	               $(HCP_BUILDER_OUT)
	$Qtouch $@

# Cleanup
ifneq (,$(wildcard $(HCP_BUILDER_OUT)))
clean_builder: | preclean
ifneq (,$(filter $(HCP_BUILDER_DNAME),$(HCP_EXISTING_IMAGES)))
	$Qdocker image rm $(HCP_BUILDER_DNAME)
endif
	$Qrm -rf $(HCP_BUILDER_OUT)
clean_base: clean_builder
endif
