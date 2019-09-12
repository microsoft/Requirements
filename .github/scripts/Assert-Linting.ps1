<#
.SYNOPSIS
    Asserts that the repo has valid coding style
.DESCRIPTION
    Runs PSScriptAnalyzer on all the PowerShell scripts in the repo, prints out the list of discovered issues, and
    writes a message to the output stream associated with the highest-severity of issue found.
#>

$ErrorActionPreference = "Stop"

Import-Module PSScriptAnalyzer

$RepoRoot = "$PSScriptRoot/../.."

$issues = Invoke-ScriptAnalyzer -Path $RepoRoot -Recurse
if ($issues) {
    $issues | Format-Table
    throw "Encountered $($issues.Count) linting issues"
}
