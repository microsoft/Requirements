

function invoke($Requirement) {
  [RequirementEvent]@{
    Requirement = $Requirement
    Method      = "Test"
    State       = "Begin"
  }
  [RequirementEvent]@{
    Requirement = $Requirement
    Method      = "Test"
    State       = "End"
    Result      = $false
  }
  [RequirementEvent]@{
    Requirement = $Requirement
    Method      = "Set"
    State       = "Begin"
  }
  [RequirementEvent]@{
    Requirement = $Requirement
    Method      = "Set"
    State       = "End"
    Result      = $null
  }
  [RequirementEvent]@{
    Requirement = $Requirement
    Method      = "Validate"
    State       = "Begin"
  }
  [RequirementEvent]@{
    Requirement = $Requirement
    Method      = "Validate"
    State       = "End"
    Result      = $true
  }
}


# $output = @"
# 00:00:00 [name] BEGIN TEST description
# 00:00:00 [name] END TEST => $false
# 00:00:00 [name] BEGIN SET description
# 00:00:00 [name] END SET
# 00:00:00 [name] BEGIN TEST description
# 00:00:00 [name] END TEST => $true
# "@


# It "Should write to host correctly" -Skip {
#   # convert Host stream to array by writing to then reading from file
#   $tempFile = "$env:TEMP\$(New-Guid).out.txt"
#   try {
#     Invoke-ChecklistRequirement `
#       -Describe "Simple Requirement" `
#       -Test { $script:ValidRequirementHasRun } `
#       -Set { $script:ValidRequirementHasRun = $true } `
#       *> $tempFile
#     $output = Get-Content $tempFile
#     $loggedOutput = $output | ? { $_.Trim() }
#     $clearedOutput = $output | ? { -not $_.Trim() }
#     $loggedOutput | % { $_ | Should -Match }
#     $clearedOutput.Count | Should -Be 1
#     $loggedOutput.Count | Should -Be 2
#   }
#   finally {
#     Remove-Item $tempFile
#   }
# }



Describe "formatters" {
  Mock Get-Date { "00:00:00" }
  $events = invoke $Requirement
  Context "Format-Table" {
    $output = $events | Format-Table | Out-String
    It "Should print a non-empty table" {
      $output.Length | Should -BeGreaterThan 10
    }
  }
  Context "Format-Checklist" {
    $output = $events | Format-Checklist | Out-String
    It "Should format each line as a checklist" {
      $output | % { $_ | Should -Match "^\d\d:\d\d:\d\d \[ . \] Simple Requirement$" }
    }
    It "Should print N lines" {
      $output.Count | Should -Be 10
    }
  }
  Context "Format-Callstack" {
    $output = $events | Format-Callstack | Out-String
    It "Should format each line as a callstack" {

    }
    It "Should print N lines" {
      $output.Count | Should -Be 1
    }
  }
}