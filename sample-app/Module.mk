
.PHONY: help-app
help-app:
	@echo "Usage:"
	@echo "    make appAssemble - Assembles main outputs"


APP_APK_DIR := sample-app/build/outputs/apk
APP_VERSION_NAME := $(shell grep -m 1 "versionName" sample-app/build.gradle.kts | sed -E 's/.*"(.+)"$$/\1/')
APP_ARCHIVE_BASE_NAME ?= keyple-plugin-sample-app-${APP_VERSION_NAME}

$(APP_APK_DIR)/%.apk:
	@echo "$@"
	$(BUILD_DOCKER_CMD) $(GRADLE) sample-app:$(GRADLE_TASK)

APP_DEBUG := $(addprefix $(APP_APK_DIR)/debug/, $(APP_ARCHIVE_BASE_NAME)-debug.apk)
.PHONY: appAssemble
appAssembleDebug: GRADLE_TASK := assembleDebug
appAssembleDebug: $(APP_DEBUG)
	@echo "$@"

APP_RELEASE := $(addprefix $(APP_APK_DIR)/release/, $(APP_ARCHIVE_BASE_NAME)-release.apk)
.PHONY: appAssemble
appAssembleRelease: GRADLE_TASK := assembleRelease
appAssembleRelease: $(APP_RELEASE)
	@echo "$@"

appAssemble: appAssembleRelease appAssembleDebug
	@echo "$@"

$(call dist-for-goals, appAssembleRelease, $(APP_RELEASE))
