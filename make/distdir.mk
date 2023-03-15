#
# Copyright (C) 2007 The Android Open Source Project
# Copyright (C) 2023 Famoco
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# When specifying "dist", the user has asked that we copy the important
# files from this build into DIST_DIR.

empty :=
space := $(empty) $(empty)

.PHONY: dist
dist: ;

.PHONY: s3
s3: ;

dist_goal := $(strip $(filter dist,$(MAKECMDGOALS)))
s3_goal := $(strip $(filter s3,$(MAKECMDGOALS)))
MAKECMDGOALS := $(strip $(filter-out dist s3,$(MAKECMDGOALS)))
ifeq (,$(strip $(filter-out $(INTERNAL_MODIFIER_TARGETS),$(MAKECMDGOALS))))
# The commandline was something like "make dist" or "make dist showcommands".
# Add a dependency on a real target.
dist: $(DEFAULT_GOAL)
s3: $(DEFAULT_GOAL)
endif

ifdef dist_goal

# The same as copy-file-to-new-target, but use the local
# cp command instead of acp.
define copy-file-to-new-target-with-cp
@mkdir -p $(dir $@)
$(hide) cp -f $< $@
endef

# Copy a single file from one place to S3 bucket
define copy-file-to-s3-bucket
$(hide) $(AWS) s3 cp $< $(S3_BUCKET)/$@
endef

# Presign a S3 file
define presign_s3_file
$(hide) $(AWS) s3 presign $(S3_BUCKET)/$@
endef

ifdef s3_goal

$(if $(AWS_ACCESS_KEY_ID),, $(error AWS_ACCESS_KEY_ID is not defined))
$(if $(AWS_SECRET_ACCESS_KEY),, $(error AWS_SECRET_ACCESS_KEY is not defined))

DIST_DIR ?= $(shell git config --local remote.origin.url | sed -r 's#\w+://[^/]*/(.*)#\1#')
S3_BUCKET ?= s3://famoco-mob
AWS_DEFAULT_REGION ?= eu-west-1
AWS_PRESIGN ?= true
ifneq ($(SKIP_DOCKER),true)
  DOCKER_ARGS ?= -v "$(PWD)":/aws -w /aws
  AWS := docker run --rm \
    -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
    $(if $(AWS_DEFAULT_REGION), -e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION)) \
    $(DOCKER_ARGS) amazon/aws-cli
else
  AWS := aws
endif

# $(1): source file
# $(2): destination file
# $(3): goals that should copy the file
#
define copy-one-dist-file
$(3): $(2)
$(2): $(1)
	@echo "Dist: $$@"
	$$(copy-file-to-s3-bucket)
ifeq ($(AWS_PRESIGN),true)
	@echo "Presign: $$@"
	$$(presign_s3_file)
endif
endef

else # !s3_goal

DIST_DIR ?= dist

define copy-one-dist-file
$(3): $(2)
$(2): $(1)
	@echo "Dist: $$@"
	$$(copy-file-to-new-target-with-cp)
endef

endif

# A global variable to remember all dist'ed src:dst pairs.
# So if a src:dst is already dist'ed by another goal,
# we should just establish the dependency and don't really call the
# copy-one-dist-file to avoid multiple rules for the same target.
_all_dist_src_dst_pairs :=
# Other parts of the system should use this function to associate
# certain files with certain goals.  When those goals are built
# and "dist" is specified, the marked files will be copied to DIST_DIR.
#
# $(1): a list of goals  (e.g. droid, sdk, pdk, ndk)
# $(2): the dist files to add to those goals.  If the file contains ':',
#       the text following the colon is the name that the file is copied
#       to under the dist directory.  Subdirs are ok, and will be created
#       at copy time if necessary.
define dist-for-goals
$(foreach file,$(2), \
  $(eval fw := $(subst :,$(space),$(file))) \
  $(eval src := $(word 1,$(fw))) \
  $(eval dst := $(word 2,$(fw))) \
  $(eval dst := $(if $(dst),$(dst),$(notdir $(src)))) \
  $(if $(filter $(_all_dist_src_dst_pairs),$(src):$(dst)),\
    $(eval $(call add-dependency,$(1),$(DIST_DIR)/$(dst))),\
    $(eval $(call copy-one-dist-file,\
      $(src),$(DIST_DIR)/$(dst),$(1)))\
      $(eval _all_dist_src_dst_pairs += $(src):$(dst))\
  )\
)
endef

else # !dist_goal

# empty definition when not building dist
define dist-for-goals
endef

endif # !dist_goal

###########################################################
## Function we can evaluate to introduce a dynamic dependency
###########################################################

define add-dependency
$(1): $(2)
endef
