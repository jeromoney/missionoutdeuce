# Fails when a Dart source file contains a hardcoded capitalized string
# literal inside Text(...). Mirrors check_no_hardcoded_strings.sh for
# Windows contributors who run hooks through PowerShell.
#
# Add `// i18n-ignore` to a line to suppress the check for that line.

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiDir = Resolve-Path (Join-Path $scriptDir '..')

$searchPaths = @(
  (Join-Path $uiDir 'dispatcher\lib'),
  (Join-Path $uiDir 'responder\lib'),
  (Join-Path $uiDir 'team_admin\lib'),
  (Join-Path $uiDir 'shared_auth\lib')
) | Where-Object { Test-Path $_ }

if ($searchPaths.Count -eq 0) {
  Write-Output 'check_no_hardcoded_strings: no Dart source directories found'
  exit 0
}

# Capitalized string literal inside Text(...). Covers ~90% of user-facing prose.
$pattern = 'Text\(\s*[''"][A-Z]'

$dartFiles = Get-ChildItem -Path $searchPaths -Recurse -File -Filter *.dart |
  Where-Object {
    $_.FullName -notmatch '\\l10n\\' -and
    $_.FullName -notmatch '\\generated\\' -and
    $_.Name -notlike '*.g.dart' -and
    $_.Name -notlike '*.freezed.dart'
  }

$hits = $dartFiles |
  Select-String -Pattern $pattern |
  Where-Object { $_.Line -notmatch 'i18n-ignore' }

if (-not $hits) {
  exit 0
}

Write-Error -Message "Hardcoded user-facing strings found. Move them to ARB or annotate the line with '// i18n-ignore':" -ErrorAction Continue
foreach ($hit in $hits) {
  Write-Output ("{0}:{1}:{2}" -f $hit.Path, $hit.LineNumber, $hit.Line.Trim())
}
exit 1
