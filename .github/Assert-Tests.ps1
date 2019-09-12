<#
.SYNOPSIS
    Throws an error if any Pester tests fail
#>

$ErrorActionPreference = "Stop"

Import-Module "Pester", "$PSScriptRoot/powershell-helpers.psm1"

Push-Location "$PSScriptRoot/.."
try {
    $results = Invoke-Pester -PassThru
    if ($results.FailedCount) {
        throw "Unit Tests failed"
    }
}
finally {
    Pop-Location
}
