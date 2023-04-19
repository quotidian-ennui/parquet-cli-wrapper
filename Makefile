##
## Lets build parquet-cli
MAKEFLAGS+= --silent --always-make
.DEFAULT_TARGET: help
MAVEN:=mvn
CURL:=curl -fsSL
SHELL:=bash

REQUIRED_BINARIES:=mvn curl java unzip

BUILD_DIR:=$(CURDIR)/build
PACKAGE_DIR:=$(BUILD_DIR)/dist
PACKAGE_LIB_DIR:=$(PACKAGE_DIR)/lib
ARCHIVE_NAME:=apache-parquet-mr.zip
PACKAGE_NAME:=parquet-cli.tar.gz

help:
	grep -E '^[a-zA-Z_-]+.*:.*?## .*$$' $(word 1,$(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check_binaries:
	$(foreach bin,$(REQUIRED_BINARIES),$(if $(shell command -v $(bin) 2> /dev/null),,$(error Please install `$(bin)`)))

clean:
	rm -rf $(BUILD_DIR)

build:  check_binaries ## Build the apache parquet-cli tool
ifndef PARQUET_VERSION
	$(error PARQUET_VERSION environment variable not set)
endif
	mkdir -p $(BUILD_DIR) $(PACKAGE_DIR)/lib
	$(CURL) -o $(BUILD_DIR)/$(ARCHIVE_NAME) https://github.com/apache/parquet-mr/archive/refs/tags/apache-parquet-$(PARQUET_VERSION).zip
	{ \
		cd $(BUILD_DIR); \
		unzip -o -qq ./$(ARCHIVE_NAME); \
		cd parquet-mr-apache-parquet-$(PARQUET_VERSION)/parquet-cli; \
		mvn clean install -DskipTests; \
		mvn dependency:copy-dependencies; \
		cp target/parquet-cli-$(PARQUET_VERSION).jar $(PACKAGE_LIB_DIR);\
		cp target/dependency/* $(PACKAGE_LIB_DIR); \
	}
	cp parquet $(PACKAGE_DIR)

bundle: build ## create a zip file bundle
	{\
		cd $(PACKAGE_DIR); \
		tar -czf ../$(PACKAGE_NAME) *; \
	}
