PACKAGE = slacker
ORG = amylum

BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz

PACKAGE_VERSION = $$(git --git-dir=upstream/.git describe --tags)
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)

.PHONY : default submodule build_container manual container build version push local

default: submodule container

submodule:
	git submodule update --init

build_container:
	docker build -t slacker-pkg meta

manual: submodule build_container
	./meta/launch /bin/bash || true

container: build_container
	./meta/launch

build: submodule
	rm -rf $(BUILD_DIR)
	cp -R upstream $(BUILD_DIR)
	cd $(BUILD_DIR) && go build -o slacker
	mkdir -p $(RELEASE_DIR)/usr/bin $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)
	cp upstream/LICENSE $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)/LICENSE
	cp $(BUILD_DIR)/slacker $(RELEASE_DIR)/usr/bin/
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)
	@sha512sum $(RELEASE_FILE) | cut -d' ' -f1

local: build push

