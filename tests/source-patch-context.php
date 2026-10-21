<?php
// Regression test for patch application inside a parent Git checkout.
// Usage: php tests/source-patch-context.php /path/to/php-8.1.34.tar.xz
$archive = realpath($argv[1] ?? '');
if ($archive === false || !is_file($archive)) {
    throw new RuntimeException('Pass the pristine PHP 8.1.34 source archive.');
}
$fixture = sys_get_temp_dir() . '/php2shell-patch-test-' . bin2hex(random_bytes(8));
$source = $fixture . '/.build/source/php-src';
mkdir($source, 0755, true);
$run = static function (string $command): string {
    exec($command . ' 2>&1', $output, $status);
    if ($status !== 0) {
        throw new RuntimeException($command . "\n" . implode("\n", $output));
    }
    return implode("\n", $output);
};
try {
    $run('git init --quiet ' . escapeshellarg($fixture));
    $run('tar -xf ' . escapeshellarg($archive) . ' --no-same-owner --strip-components=1 -C ' . escapeshellarg($source));
    if (realpath($run('git -C ' . escapeshellarg($source) . ' rev-parse --show-toplevel')) !== realpath($fixture)) {
        throw new RuntimeException('Fixture must be inside the parent Git worktree.');
    }
    define('SOURCE_PATH', dirname($source));
    $probe = new class {
        public string $point = 'after-php-extract';
        public function getPatchPoint(): string { return $this->point; }
        public function run(): void { require dirname(__DIR__) . '/scripts/spc-patch.php'; }
    };
    $probe->run();
    $probe->point = 'before-php-make';
    $probe->run();
    $provenance = json_decode(file_get_contents($source . '/PHP2SHELL-PROVENANCE.json'), true, 512, JSON_THROW_ON_ERROR);
    if ($provenance['version'] !== '8.1.34-php2shell.1') {
        throw new RuntimeException('Unexpected patched-source provenance.');
    }
    echo "Nested-worktree source patch regression passed\n";
} finally {
    // Only the private fixture created above is removed; never follow links.
    $entries = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($fixture, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::CHILD_FIRST
    );
    foreach ($entries as $entry) {
        if ($entry->isDir() && !$entry->isLink()) { rmdir($entry->getPathname()); }
        else { unlink($entry->getPathname()); }
    }
    rmdir($fixture);
}
