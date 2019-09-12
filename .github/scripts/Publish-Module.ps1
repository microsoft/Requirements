<#
.SYNOPSIS
    Throws an error if any Pester tests fail
#>

$InformationPreference = "Continue"

$RepoRoot = "$PSScriptRoot/../.."
$ModuleManifestPath = "$RepoRoot/Requirements.psd1"

(Find-Module Requirements).Version -match "(\d+)\.(\d+)\.(\d+)" | Out-Null
$major, $minor, $build = $Matches[1..3]
$nextVersion = "$major.$minor.$($build + 1)"

$template = Get-Content $ModuleManifestPath -Raw
$expanded = $template -replace "{{MODULE_VERSION}}", $nextVersion
$expanded | Out-File $ModuleManifestPath -Force

Publish-Module -Path $RepoRoot -NuGetApiKey $env:PSGALLERY_NUGET_API_KEY -WhatIf
