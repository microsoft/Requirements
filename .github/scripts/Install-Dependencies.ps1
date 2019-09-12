
$ErrorActionPreference = "Stop"

$Dependencies = @(
    "Pester",
    "PSScriptAnalyzer"
)

$Dependencies `
| ? { -not (Get-Module $_ -ListAvailable) } `
| % { Install-Module $_ }
