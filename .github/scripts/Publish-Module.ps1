<#
.SYNOPSIS
    Throws an error if any Pester tests fail
#>

$InformationPreference = "Continue"

# static version parts
$Major = 2
$Minor = 3

# paths
$RepoRoot = "$PSScriptRoot/../.."
$StagingRoot = "$PSScriptRoot/Requirements"

##
# Stage source files
#

New-Item -ItemType Directory -Path $StagingRoot
Copy-Item -Path "$RepoRoot/LICENSE", "$RepoRoot/src" -Destination $StagingRoot -Recurse

##
# Derive version string
#

$current = [Version](Find-Module Requirements).Version

$newMinor = [version]"$Major.$Minor.0" # the version to use if we incremented Minor
$newBuild = [version]"$Major.$Minor.$($current.Build + 1)" # the version to use if we increment Build
$new = if ($newMinor -gt $current) { $newMinor } else { $newBuild }

##
# Expand manifest template
#

$template = Get-Content "$RepoRoot/Requirements.psd1" -Raw
$expanded = $template -replace "{{ModuleVersion}}", $new
$expanded | Out-File "$StagingRoot/Requirements.psd1" -Force

##
# Publish the module
#

Publish-Module -Path $StagingRoot -NuGetApiKey $env:PSGALLERY_NUGET_API_KEY
