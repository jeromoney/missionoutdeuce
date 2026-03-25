param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dispatcherRoot = Split-Path -Parent $scriptDir
$repoRoot = Split-Path -Parent $dispatcherRoot
$defaultEnvFile = Join-Path (Split-Path -Parent $repoRoot) "Secrets\missionout-backend.env"
$envFile = $env:MISSIONOUT_DISPATCHER_ENV_FILE

if ([string]::IsNullOrWhiteSpace($envFile)) {
    $envFile = $defaultEnvFile
}

$commandArgs = @()
$supportsDartDefines = $false

if ($FlutterArgs.Length -gt 0) {
    $primaryCommand = $FlutterArgs[0]
    $supportsDartDefines = @("run", "build", "test") -contains $primaryCommand
}

if ($supportsDartDefines -and (Test-Path $envFile)) {
    $commandArgs += "--dart-define-from-file=$envFile"
    Write-Host "Using shared env file for dispatcher dart-defines: $envFile"
} elseif ($supportsDartDefines) {
    Write-Host "No shared env file found at $envFile. Running with existing defaults and explicit dart-defines only."
}

$commandArgs += $FlutterArgs

Push-Location $dispatcherRoot
try {
    & flutter @commandArgs
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
