

It "Should write to host correctly" -Skip {
  # convert Host stream to array by writing to then reading from file
  $tempFile = "$env:TEMP\$(New-Guid).out.txt"
  try {
    Invoke-ChecklistRequirement `
      -Describe "Simple Requirement" `
      -Test { $script:ValidRequirementHasRun } `
      -Set { $script:ValidRequirementHasRun = $true } `
      *> $tempFile
    $output = Get-Content $tempFile
    $loggedOutput = $output | ? { $_.Trim() }
    $clearedOutput = $output | ? { -not $_.Trim() }
    $loggedOutput | % { $_ | Should -Match "^\d\d:\d\d:\d\d \[ . \] Simple Requirement$" }
    $clearedOutput.Count | Should -Be 1
    $loggedOutput.Count | Should -Be 2
  }
  finally {
    Remove-Item $tempFile
  }
}

  