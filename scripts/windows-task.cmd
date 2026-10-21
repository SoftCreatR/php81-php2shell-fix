@echo off
setlocal
cd /d "%PHP2SHELL_SOURCE%"
call phpsdk_deps --update --branch 8.1 --crt vs16 --arch x64 --deps "%PHP2SHELL_DEPS%"
if errorlevel 1 exit /b 1
call buildconf.bat
if errorlevel 1 exit /b 1
call configure.bat --enable-snapshot-build --disable-zts --disable-debug-pack --without-oci8 --without-pdo-oci --with-php-build="%PHP2SHELL_DEPS%"
if errorlevel 1 exit /b 1
nmake
if errorlevel 1 exit /b 1
set "PATH=%CD%\x64\Release;%PHP2SHELL_DEPS%\bin;%PATH%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PHP2SHELL_RECIPE%\tests\windows-runtime.ps1" -PhpRoot "%CD%\x64\Release" -Version "%PHP_BUILD_VERSION%"
if errorlevel 1 exit /b 1
copy /y "%PHP2SHELL_RECIPE%\provenance.json" x64\Release\provenance.json >nul
nmake snap
if errorlevel 1 exit /b 1
exit /b 0
