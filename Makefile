##
## Lets build parquet-cli
MAKEFLAGS+= --silent --always-make
.DEFAULT_TARGET: help
MAVEN:=mvn --batch-mode --quiet
CURL:=curl -fsSL
SHELL:=bash
UPDATECLI:=updatecli

REQUIRED_BINARIES:=mvn curl java unzip jq tar

BUILD_DIR:=$(CURDIR)/build
PACKAGE_DIR:=$(BUILD_DIR)/dist
PACKAGE_LIB_DIR:=$(PACKAGE_DIR)/lib
ARCHIVE_NAME:=apache-parquet-mr.zip
PACKAGE_NAME:=parquet-cli.tar.gz

## Test Data.
TEST_DATA_DIR:=$(CURDIR)/test
TEST_CSV_FILE:=$(TEST_DATA_DIR)/users.csv
TEST_CSV_HEADERS:=name,phone,email,address,postalZip,region,country
TEST_CSV_SCHEMA:=$(BUILD_DIR)/users.schema
TEST_CSV_PARQUET:=$(BUILD_DIR)/users.parquet
TEST_CSV_NAME:=Chloe Aguilar

ifneq (,$(wildcard ./.env))
	include .env
  export
endif

help:
	grep -E '^[a-zA-Z_-]+.*:.*?## .*$$' $(word 1,$(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check_binaries:
	$(foreach bin,$(REQUIRED_BINARIES),$(if $(shell command -v $(bin) 2> /dev/null),,$(error Please install `$(bin)`)))

clean: ## Cleanup / delete build artifacts
	rm -rf $(BUILD_DIR)

build:  check_binaries ## Build the apache parquet-cli tool
ifndef PARQUET_VERSION
	$(error PARQUET_VERSION environment variable not set)
endif
	echo "--- Downloading parquet-cli ($(PARQUET_VERSION))"
	mkdir -p $(BUILD_DIR) $(PACKAGE_DIR)/lib
	$(CURL) -o $(BUILD_DIR)/$(ARCHIVE_NAME) https://github.com/apache/parquet-mr/archive/refs/tags/apache-parquet-$(PARQUET_VERSION).zip
	echo "--- Building parquet-cli"
	{ \
		cd $(BUILD_DIR); \
		unzip -o -qq ./$(ARCHIVE_NAME); \
		cd parquet-mr-apache-parquet-$(PARQUET_VERSION)/parquet-cli; \
		$(MAVEN) clean package dependency:copy-dependencies -DskipTests; \
		cp target/parquet-cli-$(PARQUET_VERSION).jar $(PACKAGE_LIB_DIR);\
		cp target/dependency/* $(PACKAGE_LIB_DIR); \
	}
	cp parquet $(PACKAGE_DIR)
	cp parquet.cmd $(PACKAGE_DIR)

bundle: build ## create a zip file bundle
	echo "--- Packaging parquet-cli"
	{ \
		cd $(PACKAGE_DIR); \
		tar -czf ../$(PACKAGE_NAME) *; \
	}

# parquet csv-schema --header name,phone,email,address,postalZip,region,country --class users users.csv
test: build ## Run a minimal set of test
	echo "--- Running Tests"
	echo "[+] parquet csv-schema"
	{ \
		cd $(PACKAGE_DIR); \
		./parquet csv-schema --header $(TEST_CSV_HEADERS) --class test $(TEST_CSV_FILE) --minimize >$(TEST_CSV_SCHEMA); \
	}
	echo "[+] parquet convert-csv"
	{ \
		cd $(PACKAGE_DIR); \
		./parquet convert-csv $(TEST_CSV_FILE) --schema $(TEST_CSV_SCHEMA) --output $(TEST_CSV_PARQUET) --overwrite; \
	}
	echo "[+] parquet head"
	{ \
		cd $(PACKAGE_DIR); \
		name=$$(./parquet head $(TEST_CSV_PARQUET) -n 1 | jq -r ".name"); \
		if [[ "$$name" != "$(TEST_CSV_NAME)" ]]; then echo "Unexpected name [$$name]" && exit 1; fi \
	}

diff: ## 'updatecli diff'
	$(UPDATECLI) diff

apply: ## 'updatecli apply'
	$(UPDATECLI) apply
