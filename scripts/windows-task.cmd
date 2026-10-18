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
x64\Release\php.exe -n -d extension_dir=x64\Release -d extension=curl -d extension=fileinfo -d extension=gd -d extension=gmp -d extension=intl -d extension=mbstring -d extension=mysqli -d extension=openssl -d extension=pdo_mysql -d extension=zip "%PHP2SHELL_RECIPE%\tests\runtime.php"
if errorlevel 1 exit /b 1
copy /y "%PHP2SHELL_RECIPE%\provenance.json" x64\Release\provenance.json >nul
nmake snap
if errorlevel 1 exit /b 1
exit /b 0
