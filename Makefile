
SKIP_DOCKER := false
GRADLE ?= ./gradlew

MAKE_DIR := make
MODULE_LIST :=

ifneq ($(SKIP_DOCKER),true)
  UID := $(shell id -u)
  REGISTRY_URL := registry-internal.global.famoco.com:5000
  BUILD_DOCKER_IMG := $(REGISTRY_URL)/famoco/android-sdk-tools-31-jdk11:1.0

  # BUILD_DOCKER_CMD is a lazy variable to allow DOCKER_ARGS customization
  BUILD_DOCKER_CMD = docker run --rm --user $(UID):1000 \
     -v "$(PWD)":/home/gradle/project -w /home/gradle/project $(DOCKER_ARGS) $(BUILD_DOCKER_IMG)
endif

SUPPORTED_COMMANDS := $(GRADLE) assemble
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  # use the rest as arguments for the command
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  COMMAND_ARGS := $(subst :,\:,$(COMMAND_ARGS))
  # ...and turn them into do-nothing targets
  $(eval $(COMMAND_ARGS):;@:)
endif

.PHONY: default
default: help

.PHONY: help
help:
	@echo "Management commands for keyple-plugin-pcl-lib:"
	@echo
	@echo "Usage:"
	@echo "    make <module>Assemble<variant>           Build module for a specific variant."
	@echo "    make <module>Assemble<variant> dist [s3] Copy the dist'ed artifacts to DIST_DIR, by default 'dist'."
	@echo "    make gradle <arguments>                  Run gradle with the given arguments."
	@echo '    make javadoc                             Generate java doc.'
	@echo "    make test                                Run tests."
	@echo "    make clean                               Clean the build directory."
	@echo
	@echo "Modules: $(MODULE_LIST)"
	@echo

.PHONY: assemble
assemble: $(COMMAND_ARGS)
	@echo "assembling"

.PHONY: clean
clean:
	@echo "cleaning"
	$(hide) $(BUILD_DOCKER_CMD) $(GRADLE) clean
	$(hide) rm -rf ? dist

.PHONY: javadoc
javadoc:
	@echo "generating javadoc"
	$(BUILD_DOCKER_CMD) $(GRADLE) dokkaJavadoc

.PHONY: test
test:
	@echo "testing"
	$(hide) $(BUILD_DOCKER_CMD) $(GRADLE) test

.PHONY: gradle
gradle:
	$(hide) $(BUILD_DOCKER_CMD) $(GRADLE) $(COMMAND_ARGS)

include $(MAKE_DIR)/misc.mk $(MAKE_DIR)/distdir.mk $(MAKE_DIR)/sign.mk

subdir_makefiles := $(shell find * -name "Module.mk")
$(foreach mk, $(subdir_makefiles), $(info including $(mk) ...) \
  $(eval include $(mk)) \
  $(eval MODULE_LIST+=$(notdir $(realpath $(dir $(mk))))) \
)
