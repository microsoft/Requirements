
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



$output = @"
00:00:00 [name] BEGIN TEST description
00:00:00 [name] END TEST => $false
00:00:00 [name] BEGIN SET description
00:00:00 [name] END SET
00:00:00 [name] BEGIN TEST description
00:00:00 [name] END TEST => $true
"@

Describe "StreamLogger" {
  Mock Get-Date { "00:00:00" }
  It "Should output correctly" {
    $name, $description = "name", "description"
    $logger.BeginPrecheck($name, $description)
    $logger.EndPrecheck($false)
    $logger.BeginSet($name, $description)
    $logger.EndSet()
    $logger.BeginValidate($name, $description)
    $logger.EndValidate($true)

  }
}
