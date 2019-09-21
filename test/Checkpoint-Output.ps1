<#
.SYNOPSIS
  Save output of formatters so that output of commands are diffed in tests
.NOTES
  Called in a precommit git hook
#>

$ErrorActionPreference = "Stop"

throw "block commit test"

$RepoRoot = "$PSScriptRoot/.."
$OutRoot = "$PSScriptRoot/integration"

."$RepoRoot/src/interface.ps1"

@{
  Describe = "Integration test output root '$OutRoot' exists"
  Test     = { Test-Path $OutRoot -PathType Container }
  Set      = { New-Item -ItemType Directory -Path $OutRoot }
} | Invoke-Requirement | Out-Null

$context = @{count = 0}

$Requirements = @{
  Test    = @{
    Name     = "MyName"
    Describe = "MyDescribe"
    Test     = { $true }
  }
  Set     = @{
    Name     = "MyName"
    Describe = "MyDescribe"
    Set      = { $true }
  }
  TestSet = @{
    Name     = "MyName"
    Describe = "MyDescribe"
    Test     = { $context.count++ % 2 -eq 1 }
    Set      = { $true }
  }
}

$Requirements.Keys `
| % {
  $events = $Requirements[$_] | Invoke-Requirement
  $events | Format-CallStack *> "$OutRoot/Format-CallStack.$_.txt"
  $events | Format-Checklist *> "$OutRoot/Format-Checklist.$_.txt"
  $events | Format-Table *> "$OutRoot/Format-Table.$_.txt"
}
