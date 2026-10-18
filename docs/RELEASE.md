Unofficial PHP 8.1.34 builds containing the PHP team's source backport for
**CVE-2026-109618** and **CVE-2026-109619** (PHP2Shell).

The upstream base and `PHP_VERSION_ID=80134` are unchanged. The public downstream
build identifier is `8.1.34-php2shell.1`. Windows x64 NTS and self-contained Linux
x86_64 CLI/CGI/FPM builds are included, with checksums, source and provenance.

This release is **not** general PHP 8.1 security support or an official PHP release.
It does not claim to address other vulnerabilities in PHP 8.1. Upgrade to a supported
branch if your application permits it. Restart every old web worker after installing
and verify the runtime used by the actual web application.

See the README and usage guide before deploying. Existing third-party modules need
matching API/architecture/TS-NTS/compiler settings and must be tested. Bundled PHP
extensions, including OPcache, are rebuilt from the patched source.
