<#
.SYNOPSIS
    Throws an error if any Pester tests fail
#>

$InformationPreference = "Continue"

$RepoRoot = "$PSScriptRoot/../.."
$ModuleManifestPath = "$RepoRoot/Requirements.psd1"

$currentVersion = [Version](Find-Module Requirements).Version

$nextVersion = "$($currentVersion.Major).($currentVersion.Minor).$($currentVersion.Build + 1)"

$template = Get-Content $ModuleManifestPath -Raw
$expanded = $template -replace "{{MODULE_VERSION}}", $nextVersion
$expanded | Out-File $ModuleManifestPath -Force

Publish-Module -Path $ModuleManifestPath -NuGetApiKey $env:PSGALLERY_NUGET_API_KEY -WhatIf
