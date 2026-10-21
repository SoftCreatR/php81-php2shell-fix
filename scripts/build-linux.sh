#!/usr/bin/env bash
set -euo pipefail
trap 'printf "Linux build failed at script line %s\n" "$LINENO" >&2' ERR
RECIPE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${BUILD_ROOT:-${RECIPE_ROOT}/.build/linux}"
OUTPUT_ROOT="${RECIPE_ROOT}/dist"
export PHP_BUILD_VERSION="${PHP_BUILD_VERSION:-8.1.34-php2shell.1}"
EXTENSIONS="bcmath,ctype,curl,dom,exif,fileinfo,filter,gd,gettext,gmp,iconv,intl,libxml,mbregex,mbstring,mysqli,mysqlnd,opcache,openssl,pdo,pdo_mysql,phar,session,simplexml,sodium,tokenizer,xml,xmlreader,xmlwriter,zip,zlib"
mkdir -p -- "${BUILD_ROOT}" "${OUTPUT_ROOT}"
cd -- "${BUILD_ROOT}"
if [[ ! -x spc ]]; then
  curl --fail --location --silent --show-error https://github.com/crazywhalecc/static-php-cli/releases/download/2.8.5/spc-linux-x86_64.tar.gz --output spc.tar.gz
  tar -xzf spc.tar.gz
fi
./spc --version
./spc doctor --no-interaction
./spc download --with-php=8.1.34 --ignore-cache-sources=php-src --for-extensions="${EXTENSIONS}" --for-libs=freetype,libjpeg,libwebp --without-suggestions --no-interaction
./spc build --build-cli --build-cgi --build-fpm --with-added-patch="${RECIPE_ROOT}/scripts/spc-patch.php" --with-libs=freetype,libjpeg,libwebp --no-interaction "${EXTENSIONS}"
PHP="${BUILD_ROOT}/buildroot/bin/php"
if ! actual_version="$("${PHP}" -n -r 'echo PHP_VERSION;')"; then
  printf 'The compiled PHP could not report its version. Output: %s\n' "${actual_version}" >&2
  exit 1
fi
printf 'Runtime identity: expected=%s actual=%s\n' "${PHP_BUILD_VERSION}" "${actual_version}"
if [[ "${actual_version}" != "${PHP_BUILD_VERSION}" ]]; then
  echo 'The compiled PHP version does not match the requested build identity.' >&2
  exit 1
fi
"${PHP}" -n "${RECIPE_ROOT}/tests/runtime.php"
"${PHP}" -n "${RECIPE_ROOT}/tests/source-patch-context.php" "${BUILD_ROOT}/downloads/php-8.1.34.tar.xz"
for binary in php php-cgi php-fpm; do
  test -x "buildroot/bin/${binary}"
  if readelf -l "buildroot/bin/${binary}" | grep -q 'Requesting program interpreter'; then
    echo "Not self-contained: ${binary}" >&2
    exit 1
  fi
done
bash "${RECIPE_ROOT}/tests/linux-fpm.sh" "${BUILD_ROOT}/buildroot/bin"
STAGING="$(mktemp -d)"
trap 'rm -rf -- "${STAGING}"' EXIT
install -m 0755 buildroot/bin/php buildroot/bin/php-cgi buildroot/bin/php-fpm "${STAGING}/"
cp source/php-src/LICENSE "${STAGING}/PHP-LICENSE"
cp "${RECIPE_ROOT}/provenance.json" "${STAGING}/provenance.json"
cp "${RECIPE_ROOT}/README.md" "${STAGING}/README.md"
tar -czf "${OUTPUT_ROOT}/php-${PHP_BUILD_VERSION}-linux-x86_64.tar.gz" -C "${STAGING}" .
(cd "${OUTPUT_ROOT}" && sha256sum "php-${PHP_BUILD_VERSION}-linux-x86_64.tar.gz" > "php-${PHP_BUILD_VERSION}-linux-x86_64.tar.gz.sha256")
# Include the exact prepared PHP source with the release, not just a moving branch link.
tar --exclude=.git -czf "${OUTPUT_ROOT}/php-${PHP_BUILD_VERSION}-source.tar.gz" -C source/php-src .
