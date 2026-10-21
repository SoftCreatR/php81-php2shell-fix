<?php
// SPC v2 loads this in its builder context at each documented patch point.
$point = $this->getPatchPoint();
if ($point === 'before-php-make') {
    $header = file_get_contents(SOURCE_PATH . '/php-src/main/php_version.h');
    $expected = getenv('PHP_BUILD_VERSION') ?: '8.1.34-php2shell.1';
    preg_match('/^#define PHP_VERSION "([^"]+)"$/m', $header, $match);
    if (($match[1] ?? '') !== $expected || strpos($header, '#define PHP_VERSION_ID 80134') === false) {
        throw new RuntimeException('Configured PHP identity mismatch: expected ' . $expected . ', got ' . ($match[1] ?? '(missing)'));
    }
    echo "Configured PHP identity verified before compilation: {$expected}\n";
    return;
}
if ($point !== 'after-php-extract') {
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
    // git apply silently skips these paths when the extracted tree is below
    // the recipe's Git worktree (the default CI layout). Stop Git's discovery
    // at the source parent so patch paths are relative to the PHP source.
    $command = 'env -u GIT_DIR -u GIT_WORK_TREE ' . escapeshellarg('GIT_CEILING_DIRECTORIES=' . dirname($source)) .
        ' git -C ' . escapeshellarg($source) . ' apply ';
    passthru($command . '--check ' . escapeshellarg($recipe . '/patches/' . $patch), $status);
    if ($status !== 0) { throw new RuntimeException('Patch precondition failed: ' . $patch); }
    passthru($command . escapeshellarg($recipe . '/patches/' . $patch), $status);
    if ($status !== 0) { throw new RuntimeException('Patch application failed: ' . $patch); }
    passthru($command . '--reverse --check ' . escapeshellarg($recipe . '/patches/' . $patch), $status);
    if ($status !== 0) { throw new RuntimeException('Applied patch verification failed: ' . $patch); }
}
$header = file_get_contents($source . '/main/php_version.h');
if (strpos($header, '#define PHP_VERSION "' . $version . '"') === false) {
    throw new RuntimeException('Version patch did not change the PHP source identity');
}
$provenance['version'] = $version;
file_put_contents($source . '/PHP2SHELL-PROVENANCE.json', json_encode($provenance, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");
echo "Verified PHP2Shell backport applied to PHP 8.1.34; identity {$version}\n";
