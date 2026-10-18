param(
    [string] $BuildRoot = 'C:\php81-php2shell-build',
    [ValidateSet('8.1.34-php2shell.1')]
    [string] $Version = '8.1.34-php2shell.1'
)
$ErrorActionPreference = 'Stop'
$recipeRoot = Split-Path -Parent $PSScriptRoot
$gitBash = Join-Path ${env:ProgramFiles} 'Git\bin\bash.exe'
if (-not (Test-Path -LiteralPath $gitBash)) { throw 'Git for Windows is required.' }
New-Item -ItemType Directory -Force -Path $BuildRoot | Out-Null
$source = Join-Path $BuildRoot 'php-src'
$sdk = Join-Path $BuildRoot 'sdk'
$env:PHP_BUILD_VERSION = $Version
if (-not (Test-Path -LiteralPath $sdk)) {
    git clone --quiet --depth 1 --branch php-sdk-2.7.1 https://github.com/php/php-sdk-binary-tools.git $sdk
    if ($LASTEXITCODE -ne 0) { throw 'Could not download the PHP SDK.' }
}
if ((git -C $sdk rev-parse HEAD) -ne 'c73faaf1cce914e2fc04da5587132f8f425996af') { throw 'Unexpected PHP SDK commit.' }
& $gitBash (Join-Path $PSScriptRoot 'prepare-source.sh').Replace('\','/') $source.Replace('\','/')
if ($LASTEXITCODE -ne 0) { throw 'Source preparation failed.' }
$env:PHP2SHELL_SOURCE = $source
$env:PHP2SHELL_DEPS = Join-Path $BuildRoot 'deps'
$env:PHP2SHELL_RECIPE = $recipeRoot
& (Join-Path $sdk 'phpsdk-starter.bat') -c vs16 -a x64 -s 14.29 -t (Join-Path $PSScriptRoot 'windows-task.cmd')
if ($LASTEXITCODE -ne 0) { throw 'The Windows build or its tests failed.' }
$archive = Get-ChildItem -LiteralPath (Join-Path $source 'x64\Release') -Filter '*.zip' -File |
    Where-Object { $_.Name -like "php-$Version-nts-*" -and $_.Name -notmatch 'debug|devel|test' } |
    Select-Object -First 1
if (-not $archive) { throw 'The tested PHP runtime archive was not generated.' }
$dist = Join-Path $recipeRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$target = Join-Path $dist "php-$Version-nts-windows-x64.zip"
Copy-Item -LiteralPath $archive.FullName -Destination $target
$hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText("$target.sha256", "$hash  $([IO.Path]::GetFileName($target))`n", [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath (Join-Path $recipeRoot 'provenance.json') -Destination (Join-Path $dist 'provenance.json')

