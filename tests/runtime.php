<?php
$expected = getenv('PHP_BUILD_VERSION') ?: '8.1.34-php2shell.1';
if (PHP_VERSION !== $expected || PHP_VERSION_ID !== 80134) {
    throw new RuntimeException('Unexpected PHP build identity: ' . PHP_VERSION);
}
$required = ['bcmath', 'ctype', 'curl', 'dom', 'exif', 'fileinfo', 'gd', 'gmp', 'intl', 'mbstring', 'mysqli', 'openssl', 'pdo_mysql', 'session', 'xml', 'zip', 'zlib'];
foreach ($required as $extension) {
    if (!extension_loaded($extension)) {
        throw new RuntimeException("Missing extension: {$extension}");
    }
}
if (!function_exists('imagewebp')) {
    throw new RuntimeException('GD must support WebP');
}
if ((new IntlDateFormatter('de_DE', 0, 0))->format(0) === false) {
    throw new RuntimeException('ICU data is missing');
}
echo 'PHP ', PHP_VERSION, ': identity and required extensions verified', PHP_EOL;
