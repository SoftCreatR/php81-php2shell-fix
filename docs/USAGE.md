# Using the standalone builds

Keep these standalone builds separate from system packages;
do not overwrite a distribution-managed `/usr/bin/php`.

## Verify a download

Download the archive and its `.sha256` file from the same GitHub release. On Linux:

```sh
sha256sum --check php-8.1.34-php2shell.1-linux-x86_64.tar.gz.sha256
mkdir php81-php2shell
tar -xzf php-8.1.34-php2shell.1-linux-x86_64.tar.gz -C php81-php2shell
./php81-php2shell/php -v
./php81-php2shell/php -m
./php81-php2shell/php -c /path/to/php.ini /path/to/script.php
```

On Windows, compare `Get-FileHash -Algorithm SHA256` with the published checksum,
extract the ZIP into a separate directory, then run `php.exe -v` and `php.exe -m`.
Use `php.ini-production` as a starting point; configure the CA bundle, timezone,
extensions and application limits for your environment. The x64 Visual C++
redistributable is required. Do not mix DLLs from different PHP branches or TS/NTS
builds.

## Linux FPM with an existing web server

Create a private FPM pool configuration appropriate for your system. For example:

```ini
[global]
daemonize = no
error_log = /var/log/php81-php2shell/fpm.log

[application]
user = www-data
group = www-data
listen = 127.0.0.1:9081
pm = ondemand
pm.max_children = 4
pm.process_idle_timeout = 10s
clear_env = yes
security.limit_extensions = .php
```

Create the log directory with suitable permissions, then start FPM under your
service manager using explicit absolute paths:

```sh
/opt/php81-php2shell/php-fpm -c /etc/php81-php2shell/php.ini \
  --fpm-config /etc/php81-php2shell/fpm.conf --nodaemonize
```

Point the existing Nginx/Caddy/Apache FastCGI backend at `127.0.0.1:9081`.
For Nginx, the PHP location typically includes:

```nginx
location ~ \.php$ {
    try_files $uri =404;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_pass 127.0.0.1:9081;
}
```

Adapt this example to the application's routing and deployment requirements.
Never expose the FPM socket/port publicly. Test the configuration before switching
traffic. Stop **every** worker from the old runtime after switching, not just the
master process. Verify `PHP_VERSION` through the actual web-serving SAPI; checking
the CLI alone does not establish that your website is patched. Remove diagnostic
pages afterward.

## What this does not provide

- No upstream PHP support or general PHP 8.1 vulnerability coverage.
- No automatic OS service installation or application migration.
- No guarantee of compatibility with arbitrary third-party binary extensions.
- No claim that changing PHP configuration replaces applying the two source fixes.

Use a currently supported PHP version if the application supports one. This build
is a narrowly scoped compatibility bridge for applications that still require 8.1.
