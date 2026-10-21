param(
    [Parameter(Mandatory=$true)] [string] $PhpRoot,
    [string] $Version = '8.1.34-php2shell.1',
    [switch] $Packaged
)
$ErrorActionPreference = 'Stop'
$php = Join-Path $PhpRoot 'php.exe'
if (-not (Test-Path -LiteralPath $php -PathType Leaf)) { throw 'PHP CLI executable is missing.' }
if (-not (Test-Path -LiteralPath (Join-Path $PhpRoot 'php-cgi.exe') -PathType Leaf)) { throw 'PHP CGI executable is missing.' }
$required = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'requirements.json') | ConvertFrom-Json
$extensionRoot = if ($Packaged) { Join-Path $PhpRoot 'ext' } else { $PhpRoot }
$phpArguments = @('-n', '-d', "extension_dir=$extensionRoot")
foreach ($extension in $required) {
    # PHP 8.1 may compile a module into php8.dll (notably ZIP). Only
    # request a dynamic load if the corresponding shared module exists.
    if (Test-Path -LiteralPath (Join-Path $extensionRoot "php_$extension.dll") -PathType Leaf) {
        $phpArguments += @('-d', "extension=$extension")
    }
}
$savedVersion = $env:PHP_BUILD_VERSION
$savedPath = $env:PATH
try {
    $env:PHP_BUILD_VERSION = $Version
    if ($Packaged) {
        # Do not let the build SDK/dependency PATH hide missing packaged DLLs.
        $env:PATH = "$PhpRoot;$env:SystemRoot\System32;$env:SystemRoot"
    }
    & $php @phpArguments (Join-Path $PSScriptRoot 'runtime.php')
    if ($LASTEXITCODE -ne 0) { throw 'PHP identity or required-extension verification failed.' }
} finally {
    $env:PHP_BUILD_VERSION = $savedVersion
    $env:PATH = $savedPath
}
