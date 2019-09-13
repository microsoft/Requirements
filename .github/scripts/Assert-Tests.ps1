<#
.SYNOPSIS
    Throws an error if any Pester tests fail
#>

Install-Module Pester -Force | Out-Null
Import-Module Pester

$RepoRoot = "$PSScriptRoot/../.."

Push-Location $RepoRoot
try {
    $results = Invoke-Pester -PassThru
    if ($results.FailedCount) {
        throw "Unit Tests failed"
    }
}
finally {
    Pop-Location
}
