
$ErrorActionPreference = "Stop"

$RepoRoot = "$PSScriptRoot/.."
$SourceRoot = "$RepoRoot/src"
."$SourceRoot\formatters.ps1"

function invoke($Requirement) {
  [RequirementEvent]::new($Requirement, "Test", "Start")
  [RequirementEvent]::new($Requirement, "Test", "Stop", $false)
  [RequirementEvent]::new($Requirement, "Set", "Start")
  [RequirementEvent]::new($Requirement, "Set", "Stop", $true)
  [RequirementEvent]::new($Requirement, "Validate", "Start")
  [RequirementEvent]::new($Requirement, "Validate", "Stop", $true)
}

Describe "formatters" {
  Mock Get-Date { return "00:00:00" }
  $script:InDesiredState = 0
  $requirement = @{
    Name     = "simple-requirement"
    Describe = "Simple Requirement"
    Test     = { $script:InDesiredState++ }
    Set      = { }
  }
  $events = invoke $requirement
  $tempContainer = $PSScriptRoot
  Context "Format-Table" {
    $output = $events | Format-Table | Out-String
    It "Should print a non-empty string" {
      $output.Trim().Length | Should -BeGreaterThan 10
    }
  }
  Context "Format-Checklist" {
    $path = "$tempContainer\$(New-Guid).txt"
    ($events | Format-Checklist) *> $path
    $output = Get-Content $path -Raw
    Remove-Item $path
    It "Should format each line as a checklist" {
      $output | Should -Match "^\d\d:\d\d:\d\d \[ . \] Simple Requirement"
    }
  }
  Context "Format-Callstack" {
    $path = "$tempContainer\$(New-Guid).txt"
    ($events | Format-CallStack) *> $path
    $output = Get-Content $path
    Remove-Item $path
    It "Should format each line as a callstack" {
      $output | % { $_ | Should -Match "^\d\d:\d\d:\d\d \[.+\] .+" }
    }
    It "Should print 6 lines" {
      $output.Count | Should -Be 6
    }
  }

  Context "Format-Checklist should never error" {
    $context = @{count = 0 }

    It "Should not throw during Test Requirements" {
      $Test = @(
        @{
          Name     = "MyName"
          Describe = "MyDescribe"
          Test     = { $context.count++ % 2 -eq 1 }
          Set      = { $true }
        }
      ) | Invoke-Requirement
      { $Test | Format-Checklist *> $null } | Should -Not -Throw
    }
    It "Should not throw during Set Requirements" {
      $Set = @(
        @{
          Name     = "MyName"
          Describe = "MyDescribe"
          Test     = { $context.count++ % 2 -eq 1 }
          Set      = { $true }
        }
      ) | Invoke-Requirement
      { $Set | Format-Checklist *> $null } | Should -Not -Throw
    }
    It "Should not throw with TestSet Requirements" {
      $TestSet = @(
        @{
          Name     = "MyName"
          Describe = "MyDescribe"
          Test     = { $context.count++ % 2 -eq 1 }
          Set      = { $true }
        }
      ) | Invoke-Requirement
      { $TestSet | Format-Checklist *> $null } | Should -Not -Throw
    }
  }

  Context "Format-Callstack should never error" {
    $context = @{count = 0 }

    It "Should not throw during Test Requirements" {
      $Test = @(
        @{
          Name     = "MyName"
          Describe = "MyDescribe"
          Test     = { $context.count++ % 2 -eq 1 }
          Set      = { $true }
        }
      ) | Invoke-Requirement
      { $Test | Format-Callstack *> $null } | Should -Not -Throw
    }
    It "Should not throw during Set Requirements" {
      $Set = @(
        @{
          Name     = "MyName"
          Describe = "MyDescribe"
          Test     = { $context.count++ % 2 -eq 1 }
          Set      = { $true }
        }
      ) | Invoke-Requirement
      { $Set | Format-Callstack *> $null } | Should -Not -Throw
    }
    It "Should not throw with TestSet Requirements" {
      $TestSet = @(
        @{
          Name     = "MyName"
          Describe = "MyDescribe"
          Test     = { $context.count++ % 2 -eq 1 }
          Set      = { $true }
        }
      ) | Invoke-Requirement
      { $TestSet | Format-Callstack *> $null } | Should -Not -Throw
    }
  }

}
