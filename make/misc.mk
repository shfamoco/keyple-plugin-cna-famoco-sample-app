#
# Copyright (C) 2023 Famoco
#


.PHONY: showcommands
showcommands: ;

ifeq ($(strip $(filter showcommands,$(MAKECMDGOALS))),)
hide := @
else
hide :=
endif
MAKECMDGOALS := $(strip $(filter-out showcommands,$(MAKECMDGOALS)))

SUPPORTED_COMMANDS := $(GRADLE)
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  # use the rest as arguments for the command
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  COMMAND_ARGS := $(subst :,\:,$(COMMAND_ARGS))
  # ...and turn them into do-nothing targets
  $(eval $(COMMAND_ARGS):;@:)
endif
