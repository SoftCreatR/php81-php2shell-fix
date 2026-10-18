<?php
// SPC v2 loads this in its builder context at each documented patch point.
if ($this->getPatchPoint() !== 'after-php-extract') {
    return;
}
$recipe = dirname(__DIR__);
$source = SOURCE_PATH . '/php-src';
$version = getenv('PHP_BUILD_VERSION') ?: '8.1.34-php2shell.1';
if ($version !== '8.1.34-php2shell.1') {
    throw new RuntimeException('Unknown build identity');
}
$provenance = json_decode(file_get_contents($recipe . '/provenance.json'), true, 512, JSON_THROW_ON_ERROR);
if (hash_file('sha256', $recipe . '/patches/php2shell.patch') !== $provenance['securityPatchSha256']) {
    throw new RuntimeException('Upstream security patch checksum mismatch');
}
$header = file_get_contents($source . '/main/php_version.h');
if (strpos($header, '#define PHP_VERSION "8.1.34"') === false) {
    throw new RuntimeException('Expected pristine PHP 8.1.34 source, refusing to patch another version');
}
foreach (['php2shell.patch', 'version.patch'] as $patch) {
    $command = 'git -C ' . escapeshellarg($source) . ' apply ';
    passthru($command . '--check ' . escapeshellarg($recipe . '/patches/' . $patch), $status);
    if ($status !== 0) { throw new RuntimeException('Patch precondition failed: ' . $patch); }
    passthru($command . escapeshellarg($recipe . '/patches/' . $patch), $status);
    if ($status !== 0) { throw new RuntimeException('Patch application failed: ' . $patch); }
}
$provenance['version'] = $version;
file_put_contents($source . '/PHP2SHELL-PROVENANCE.json', json_encode($provenance, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");
echo "Verified PHP2Shell backport applied to PHP 8.1.34; identity {$version}\n";
