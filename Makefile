### THIS IST THE VERSION WITH docker-compose

# default variables
include Makefile.inc

# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= .env
dummy_cnf := $(shell touch $(cnf) )
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

debug: check-prerequisites
	@echo "${APP_VERSION}"

check-prerequisites:
ifeq ("$(wildcard ${DOCKER})","")
	@echo "docker not found" ; exit 1
endif
ifeq ("$(wildcard ${DC})","")
	@echo "docker-compose not found" ; exit 1
endif

#
# Build dev
#
build-dev: check-run-dev ## Build the release and development container
	${DC} -f ${DC_APP_BUILD_DEV} build --no-cache

check-build-dev: check-prerequisites ## Check development compose syntax
	${DC} -f $(DC_APP_BUILD_DEV) config -q
#
# Run dev
#
check-run-dev: check-prerequisites ## Check development compose syntax
	${DC} -f $(DC_APP_BUILD_DEV) config -q

up-dev: check-run-dev ## Run container in development mode
	${DC} -f ${DC_APP_BUILD_DEV} up

down-dev: check-run-dev ## Down container in development mode
	${DC} -f ${DC_APP_BUILD_DEV} down

stop-dev: check-run-dev ## Stop container in development mode
	${DC} -f ${DC_APP_BUILD_DEV} stop
#
# run prod
#
up-prod: check-run-prod  ## Run containers in production mode
	${DC} -f ${DC_APP_RUN_PROD} up -d --no-build

check-run-prod: check-prerequisites ## Check production compose syntax
	${DC} -f $(DC_APP_RUN_PROD) config -q

down-prod: check-run-prod  ## Stop containers in production mode
	${DC} -f ${DC_APP_RUN_PROD} down

stop-prod-db: ## Stop db container in production mode
	${DC} -f ${DC_APP_RUN_PROD} stop db

stop-prod-web: ## Stop web container in production mode
	${DC} -f ${DC_APP_RUN_PROD} stop web

#
# Build prod
#
build-all: build-dir build-archive build-all-images save-images ## Create archive, Build production images, save images

build-all-images: build-dir build-prod

build-archive: clean-archive build-dir ## Build archive
	@echo "Build $(APP) $(APP)-$(APP_VERSION) archive"
	echo "$(APP_VERSION)" > VERSION ; cp VERSION $(BUILD_DIR)/$(APP)-VERSION
	tar -zcvf $(BUILD_DIR)/$(FILE_ARCHIVE_APP_VERSION) --exclude $$(basename $(BUILD_DIR)) $$( git ls-files ) VERSION
	# git archive --format=tar.gz -o $(BUILD_DIR)/$(FILE_ARCHIVE_APP_VERSION) HEAD
	@echo "Build $(APP) $(APP)-$(LATEST_VERSION) archive"
	cp $(BUILD_DIR)/$(FILE_ARCHIVE_APP_VERSION) $(BUILD_DIR)/$(FILE_ARCHIVE_LATEST_VERSION)

clean-archive:
	@echo "Clean $(APP) archive"
	rm -rf $(FILE_ARCHIVE_APP_VERSION)

build-prod: check-prerequisites check-build-prod build-prod-web build-prod-db ## Build the release and production (web && db)

check-build-prod: ## Check production docker-compose syntax
	${DC} -f $(DC_APP_BUILD_PROD) config -q

build-prod-web: ## Build production web container
	${DC} -f ${DC_APP_BUILD_PROD} build ${DC_BUILD_ARGS}

build-prod-db: ## Build production db container
	${DC} -f ${DC_APP_BUILD_PROD} pull db
	${DC} -f ${DC_APP_BUILD_PROD} build ${DC_BUILD_ARGS} db

#
# save/clean images
#
save-images: build-dir save-image-db save-image-web ## Save images

save-image-db: ## Save db image
	db_image_name=$$(${DC} -f $(DC_APP_BUILD_PROD) config | python -c 'import sys, yaml, json; cfg = json.loads(json.dumps(yaml.load(sys.stdin), sys.stdout, indent=4)); print cfg["services"]["db"]["image"]') ; \
          docker image save -o  $(BUILD_DIR)/$(FILE_IMAGE_DB_APP_VERSION) $$db_image_name && \
          cp $(BUILD_DIR)/$(FILE_IMAGE_DB_APP_VERSION) $(BUILD_DIR)/$(FILE_IMAGE_DB_LATEST_VERSION)

save-image-web: ## Save web image
	web_image_name=$$(${DC} -f $(DC_APP_BUILD_PROD) config | python -c 'import sys, yaml, json; cfg = json.loads(json.dumps(yaml.load(sys.stdin), sys.stdout, indent=4)); print cfg["services"]["web"]["image"]') ; \
          docker image save -o  $(BUILD_DIR)/$(FILE_IMAGE_WEB_APP_VERSION) $$web_image_name && \
          cp $(BUILD_DIR)/$(FILE_IMAGE_WEB_APP_VERSION)  $(BUILD_DIR)/$(FILE_IMAGE_WEB_LATEST_VERSION)

clean-images: clean-image-web clean-image-db ## Remove all docker images

clean-image-web: ## Remove web docker image
	web_image_name=$$(${DC} -f $(DC_APP_BUILD_PROD) config | python -c 'import sys, yaml, json; cfg = json.loads(json.dumps(yaml.load(sys.stdin), sys.stdout, indent=4)); print cfg["services"]["web"]["image"]') ; \
          docker rmi $$web_image_name || true

clean-image-db: ## Remove db docker image
	db_image_name=$$(${DC} -f $(DC_APP_BUILD_PROD) config | python -c 'import sys, yaml, json; cfg = json.loads(json.dumps(yaml.load(sys.stdin), sys.stdout, indent=4)); print cfg["services"]["db"]["image"]') ; \
          docker rmi $$db_image_name || true

build-dir:
	if [ ! -d "$(BUILD_DIR)" ] ; then mkdir -p $(BUILD_DIR) ; fi

clean-dir:
	if [ -d "$(BUILD_DIR)" ] ; then rm -rf $(BUILD_DIR) ; fi

#
# publish
#
publish: publish-$(APP_VERSION) publish-$(LATEST_VERSION) ## Publish all artifacts (archives,docker images)

publish-$(APP_VERSION):
	@echo "Publish $(APP) $(APP_VERSION) artifacts"
	if [ -z "$(PUBLISH_URL)" -o -z "$(PUBLISH_AUTH_TOKEN)" ] ; then exit 1 ; fi
	( cd $(BUILD_DIR) ;\
	  ls -alrt ;\
	    for file in \
                $(APP)-VERSION \
                $(FILE_ARCHIVE_APP_VERSION) \
                $(FILE_IMAGE_WEB_APP_VERSION) \
                $(FILE_IMAGE_DB_APP_VERSION) \
           ; do \
            curl -k -X PUT -T $$file -H 'X-Auth-Token: $(PUBLISH_AUTH_TOKEN)' $(PUBLISH_URL)/$(PUBLISH_URL_APP_VERSION)/$$file ; \
           done ; \
	  curl -k -H 'X-Auth-Token: $(PUBLISH_AUTH_TOKEN)' "$(PUBLISH_URL)/$(PUBLISH_URL_BASE)?prefix=${APP_VERSION}/&format=json" -s --fail ; \
	)

publish-$(LATEST_VERSION):
	@echo "Publish $(APP) $(LATEST_VERSION) artifacts"
	if [ -z "$(PUBLISH_URL)" -o -z "$(PUBLISH_AUTH_TOKEN)" ] ; then exit 1 ; fi
	( cd $(BUILD_DIR) ;\
	    for file in \
                $(APP)-VERSION \
                $(FILE_ARCHIVE_LATEST_VERSION) \
                $(FILE_IMAGE_WEB_APP_VERSION) \
                $(FILE_IMAGE_DB_APP_VERSION) \
           ; do \
            curl -k -X PUT -T $$file -H 'X-Auth-Token: $(PUBLISH_AUTH_TOKEN)' $(PUBLISH_URL)/$(PUBLISH_URL_LATEST_VERSION)/$$file ; \
           done ; \
	  curl -k -H 'X-Auth-Token: $(PUBLISH_AUTH_TOKEN)' "$(PUBLISH_URL)/$(PUBLISH_URL_BASE)?prefix=${APP_VERSION}/&format=json" -s --fail ; \
	)

#
# test
#
test-up: wait-db test-up-db test-up-web test-up-$(APP) ## Test running container (db,web,app)

wait-db: ## wait db up and running
	time bash -x tests/wait-db.sh
test-up-web: ## test web container up and runnng
	time bash -x tests/test-up-web.sh
test-up-db: ## test db container up and runnng
	time bash -x tests/test-up-db.sh
test-up-${APP}: ## test app up and running
	time bash tests/test-up-${APP}.sh
