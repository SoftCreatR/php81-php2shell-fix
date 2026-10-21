# PHP 8.1 PHP2Shell fix

Unofficial PHP **8.1.34-php2shell.1** builds for Windows and Linux, based on PHP 8.1.34
with the PHP security team's backport for **CVE-2026-109618** and
**CVE-2026-109619** (PHP2Shell).

**This is not PHP 8.1 LTS, a general security-maintenance project, or an official
PHP release.** Only the two identified fixes are included. Other PHP 8.1
vulnerabilities may remain. Prefer a supported PHP branch whenever possible.

## Provenance

- Base: [`php-8.1.34`](https://github.com/php/php-src/tree/94abff74457effe4432f0bd49f5230aa11155dff)
  (`94abff74457effe4432f0bd49f5230aa11155dff`).
- Backport: [`1d7dec178a094e6e75b229ce22754045f8c6070a`](https://github.com/php/php-src/commit/1d7dec178a094e6e75b229ce22754045f8c6070a)
  from the PHP team's `PHP-8.1-CVE-2026-109618-109619` branch.
- Downstream source change: the version identifier only (`patches/version.patch`).
- Linux builds additionally use static-php-cli's standard static-linking and
  library-compatibility adaptations; the complete resulting source is included.
- Advisory: https://www.php.net/archive/2026.php#2026-10-21-5

`8.1.34-php2shell.1` is a downstream identifier, **not** a new upstream PHP release.
The base version and `PHP_VERSION_ID=80134` remain unchanged. PHP's module API
`20210902` and Zend extension API `420210902` are preserved; build architecture,
TS/NTS mode and Windows compiler compatibility still need to match. Bundled
extensions are rebuilt. Third-party binary extensions must be tested, not assumed
safe merely because they load successfully.
No exploit, bypass, or configuration-only mitigation is substituted for the
upstream source fix. Restart **all** existing workers after installing a build.

## Builds

- Linux x86_64: self-contained CLI, CGI and FPM binaries with commonly used
  extensions, built with pinned static-php-cli 2.8.5. No replacement
  of the system PHP installation is required.
- Windows x64 NTS: CLI and CGI, built using the Visual Studio 2019 toolset and
  PHP SDK 2.7.1. Required extensions are included; the PHP 8.1 ABI is retained.

Builds are published only after runtime/extension checks and the regression
tests pass. Download the matching archive and verify its SHA-256 checksum.
The source archive and build recipes are published alongside the binaries.
GitHub Actions supplies build attestations for release binaries.

### Build locally

Linux (build dependencies must be installed; the doctor prints missing tools):

```sh
BUILD_ROOT="$PWD/.build/linux" ./scripts/build-linux.sh
```

For repeated builds, set `GITHUB_TOKEN` to a read-only GitHub token to avoid
unauthenticated API rate limits when resolving dependency releases. The GitHub
Actions workflow supplies its short-lived, read-only workflow token automatically.

Windows (Git for Windows, VS 2019 C++ v142 toolset, Windows SDK):

```powershell
.\scripts\build-windows.ps1
```

The build directories are isolated from installed PHP. Build scripts
do not install an interpreter globally or restart existing services.

See [usage examples](docs/USAGE.md) for CLI, FPM, Nginx and Windows CGI usage.
The standalone builds use the downstream identifier `8.1.34-php2shell.1`.

## Verification and scope

The release workflow verifies the exact source pins and applies the security
commit before changing the version. Tests cover required extensions, normal
requests and bounded out-of-memory shutdown behavior, including repeated FPM
requests. These checks are regression checks, not a claim to prove freedom from
every memory-safety issue. Consult the upstream advisory for vulnerability scope.

PHP and bundled dependencies retain their upstream licenses. The PHP license
and source attribution are included in the archives. Build recipes in this
repository are MIT licensed; that does not relicense PHP or its dependencies.
