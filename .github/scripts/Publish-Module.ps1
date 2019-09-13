<#
.SYNOPSIS
    Throws an error if any Pester tests fail
#>

$InformationPreference = "Continue"

$Major = 2
$Minor = 2

$RepoRoot = "$PSScriptRoot/../.."
$ModuleManifestPath = "$RepoRoot/Requirements.psd1"

$current = [Version](Find-Module Requirements).Version

$isNewMinor = $current.Major -ne $Major -or $current.Minor -ne $Minor
$build = if ($isNewMinor) { 0 } else { $currentVersion.Build + 1 }

$ModuleVersion = "$Major.$Minor.$build"

$template = Get-Content $ModuleManifestPath -Raw
$expanded = $template -replace "{{ModuleVersion}}", $ModuleVersion
$expanded | Out-File $ModuleManifestPath -Force

Publish-Module -Path $RepoRoot -NuGetApiKey $env:PSGALLERY_NUGET_API_KEY -WhatIf
