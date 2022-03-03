# A bunch of cleanup rules were repeating the same dance of checking whether a
# certain touchfile existed to indicated that an image had been built, and if
# so, declaring a rule to clean out the image and touchfile, and making that
# rule a dependency of a parent rule. This function sucks out the noise.
# $1=touchfile
# $2=image
# $3=unique id (must be different each time this is called)
# $4=parent clean rule
define pp_rule_docker_image_rm
	$(eval rname := clean_image_$(strip $3))
	$(eval pname := $(strip $4))
	$(eval tpath := $(strip $1))
	$(eval iname := $(strip $2))
ifneq (,$(wildcard $(tpath)))
$(pname): $(rname)
$(rname):
	$Qecho "Removing container image $(iname)"
	$Qecho docker image rm $(iname)
	rm $(strip $(tpath))
endif
endef
