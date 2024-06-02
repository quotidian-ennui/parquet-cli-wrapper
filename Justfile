set positional-arguments := true
set dotenv-load

REQUIRED_BINARIES:="mvn curl java unzip jq tar"
PARQUET_VERSION:=env_var("PARQUET_VERSION")
BUILD_DIR:= justfile_directory() / "build"
PACKAGE_DIR:= BUILD_DIR / "dist"
PACKAGE_LIB_DIR:= PACKAGE_DIR / "lib"
ARCHIVE_NAME:="apache-parquet-mr.zip"
PACKAGE_NAME:="parquet-cli.tar.gz"

## Test Data.
TEST_DATA_DIR:=justfile_directory() / "test"
TEST_CSV_FILE:=TEST_DATA_DIR / "users.csv"
TEST_CSV_HEADERS:="name,phone,email,address,postalZip,region,country"
TEST_CSV_SCHEMA:= BUILD_DIR / "users.schema"
TEST_CSV_PARQUET:= BUILD_DIR / "users.parquet"
TEST_CSV_NAME:="Chloe Aguilar"

# show recipes
[private]
@help:
  just --list --list-prefix "  "

[private]
check_binaries:
  #!/usr/bin/env bash
  set -eo pipefail

  required="{{ REQUIRED_BINARIES }}"
  for binary in $required; do
    if ! command -v "$binary" &> /dev/null; then
      echo "Please install $binary"
      exit 1
    fi
  done

# Cleanup / delete build artifacts
@clean:
  rm -rf "{{ BUILD_DIR }}"

# Build the apache parquet-cli tool
build: check_binaries
  #!/usr/bin/env bash
  set -eo pipefail

  echo "--- Downloading parquet-cli ({{ PARQUET_VERSION }})"
  mkdir -p "{{ BUILD_DIR }}" "{{ PACKAGE_DIR }}/lib"
  DOWNLOAD_URL="https://github.com/apache/parquet-java/archive/refs/tags/apache-parquet-{{ PARQUET_VERSION }}.zip"
  curl -fsSL -o "{{ BUILD_DIR }}/{{ ARCHIVE_NAME }}" "$DOWNLOAD_URL"
  echo "--- Building parquet-cli"
  {
    pushd "{{ BUILD_DIR }}" >/dev/null
    unzip -o -qq "./{{ ARCHIVE_NAME }}"
    parquet_cli_dir=$(find . -type d -name "parquet-cli")
    pushd "$parquet_cli_dir" >/dev/null
    mvn --batch-mode --quiet clean package dependency:copy-dependencies -DskipTests
    cp "target/parquet-cli-{{ PARQUET_VERSION }}.jar" "{{ PACKAGE_LIB_DIR }}"
    cp target/dependency/* "{{ PACKAGE_LIB_DIR }}"
    popd >/dev/null
    popd >/dev/null
  }
  cp parquet parquet.cmd "{{ PACKAGE_DIR }}"

# create a tar.gz file bundle
bundle: build
  #!/usr/bin/env bash
  set -eo pipefail

  echo "--- Packaging parquet-cli"
  cd "{{ PACKAGE_DIR }}"
  # shellcheck disable=SC2035
  tar -czf "../{{ PACKAGE_NAME }}" *


# parquet csv-schema --header name,phone,email,address,postalZip,region,country --class users users.csv
# Run minimal set of tests
test: build
  #!/usr/bin/env bash
  set -eo pipefail

  echo "--- Running Tests"
  echo "[+] parquet csv-schema"
  pushd "{{ PACKAGE_DIR }}" >/dev/null
  ./parquet csv-schema --header "{{ TEST_CSV_HEADERS }}" --class test "{{ TEST_CSV_FILE }}" --minimize > "{{ TEST_CSV_SCHEMA }}"
  echo "[+] parquet convert-csv"
  ./parquet convert-csv "{{ TEST_CSV_FILE }}" --schema "{{ TEST_CSV_SCHEMA }}" --output "{{ TEST_CSV_PARQUET }}" --overwrite
  echo "[+] parquet head"
  name=$(./parquet head "{{ TEST_CSV_PARQUET }}" -n 1 | jq -r ".name")
  if [[ "$name" != "{{ TEST_CSV_NAME }}" ]]; then
    echo "Unexpected name [$name]"
    exit 1
  fi

# run updatecli with args e.g. just updatecli diff
@updatecli action='diff':
  updatecli "$@"

# tag and optionally the tag
release tag push="localonly":
  #!/usr/bin/env bash
  set -eo pipefail

  git diff --quiet || (echo "--> git is dirty" && exit 1)
  tag="{{ tag }}"
  push="{{ push }}"
  git tag "$tag" -m"release: $tag"
  case "$push" in
    push|github)
      git push --all
      git push --tags
      ;;
    *)
      ;;
  esac
