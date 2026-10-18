#!/usr/bin/env bash
set -euo pipefail
RECIPE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${1:?Pass a fresh source directory}"
PHP_BUILD_VERSION="${PHP_BUILD_VERSION:-8.1.34-php2shell.1}"
[[ "${PHP_BUILD_VERSION}" == 8.1.34-php2shell.1 ]] || { echo 'Unsupported downstream identifier' >&2; exit 1; }
BASE=94abff74457effe4432f0bd49f5230aa11155dff
FIX=1d7dec178a094e6e75b229ce22754045f8c6070a
if [[ -e "${SOURCE_ROOT}" ]]; then
  echo "Refusing to overwrite existing source directory: ${SOURCE_ROOT}" >&2
  exit 1
fi
git clone --quiet --depth 1 --branch php-8.1.34 https://github.com/php/php-src.git "${SOURCE_ROOT}"
test "$(git -C "${SOURCE_ROOT}" rev-parse HEAD)" = "${BASE}"
# Apply just the security commit, not unrelated later commits on the EOL branch.
git -C "${SOURCE_ROOT}" apply --check "${RECIPE_ROOT}/patches/php2shell.patch"
git -C "${SOURCE_ROOT}" apply "${RECIPE_ROOT}/patches/php2shell.patch"
git -C "${SOURCE_ROOT}" apply --check "${RECIPE_ROOT}/patches/version.patch"
git -C "${SOURCE_ROOT}" apply "${RECIPE_ROOT}/patches/version.patch"
git -C "${SOURCE_ROOT}" diff HEAD --stat
cp "${RECIPE_ROOT}/provenance.json" "${SOURCE_ROOT}/PHP2SHELL-PROVENANCE.json"
