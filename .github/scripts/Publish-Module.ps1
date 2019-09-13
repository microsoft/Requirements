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

$newMinor = [version]"$Major.$Minor.0" # the version to use if we incremented Minor
$newBuild = [version]"$Major.$Minor.$($current.Build + 1)" # the version to use if we increment Build
$new = if ($newMinor -gt $current) { $newMinor } else { $newBuild }

$template = Get-Content $ModuleManifestPath -Raw
$expanded = $template -replace "{{ModuleVersion}}", $new
$expanded | Out-File $ModuleManifestPath -Force

Publish-Module -Path $RepoRoot -NuGetApiKey $env:PSGALLERY_NUGET_API_KEY -WhatIf
