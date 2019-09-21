<#
.SYNOPSIS
  Save output of formatters so that output of commands are diffed in tests
.NOTES
  Called in a precommit git hook
#>

$ErrorActionPreference = "Stop"

$RepoRoot = "$PSScriptRoot/.."
$OutRoot = "$PSScriptRoot/integration"

."$RepoRoot/src/interface.ps1"

Invoke-Requirement @{
  Describe = "Integration test output root '$OutRoot' exists"
  Test     = { Test-Path $OutRoot -PathType Container }
  Set      = { New-Item -ItemType Directory -Path $OutRoot }
}

$Requirements = @{
  Test    = @{
    Name     = "MyName"
    Describe = "MyDescribe"
    Test     = { $context.count++ % 2 -eq 1 }
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
