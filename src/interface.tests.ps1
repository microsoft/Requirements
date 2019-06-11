
$ErrorActionPreference = "Stop"
."$PSScriptRoot\interface.ps1"

$PlatformLacksDscSupport = $PSVersionTable.Platform -eq "Unix"

Describe "New-Requirement" {
  Context "'ApplyIfNeeded' parameter set" {
    $requirement = @{
      Describe = "My Requirement"
      Test     = { 1 }
      Set      = { 2 }
    }
    It "Should not throw" {
      { New-Requirement @requirement } | Should -Not -Throw
    }
    It "Should not be empty" {
      New-Requirement @requirement | Should -Not -BeNullOrEmpty
    }
  }
  Context "'Dsc' parameter set" {
    It "Should not be empty" -Skip:$PlatformLacksDscSupport {
      $requirement = @{
        Describe     = "My Dsc Requirement"
        ResourceName = "File"
        ModuleName   = "PSDesiredStateConfiguration"
        Property     = @{
          Contents        = ""
          DestinationFile = ""
        }
      }
      New-Requirement @requirement | Should -Not -BeNullOrEmpty
    }
  }
}

Describe "Invoke-Requirement" {
  Context "Normal Requirement" {
    It "Should not error" {
      $requirement = @{
        Test = { 1 }
      }
      { Invoke-Requirement $requirement } | Should -Not -Throw
    }
  }
  Context "DSC Requirement" {
    It "Should apply the DSC resource" -Skip:$PlatformLacksDscSupport {
      $tempFile = "$env:TEMP\$(New-Guid).txt"
      $content = "Hello world"
      $requirement = @{
        Describe     = "My Dsc Requirement"
        ResourceName = "File"
        ModuleName   = "PSDesiredStateConfiguration"
        Property     = @{
          Contents        = $content
          DestinationFile = $tempFilePath
        }
      }
      Invoke-Requirement (New-Requirement @requirement)
      Get-Content $tempFile | Should -Be $content
      Remove-Item $tempFilePath
    }
  }
}

Describe "Test-Requirement" {
  It "Should not error" {
    $requirement = @{
      Test = { $true }
    }
    { Test-Requirement $requirement } | Should -Not -Throw
  }
  It "Should pass through falsey values" {
    $requirement = @{
      Test = { $false }
    }
    Test-Requirement $requirement | Should -BeFalse
  }
  It "Should pass through truthy values" {
    $requirement = @{
      Test = { $true }
    }
    Test-Requirement $requirement | Should -BeTrue
  }
}

Describe "Set-Requirement" {
  It "Should not error" {
    $requirement = @{
      Set = { $false }
    }
    { Invoke-Requirement $requirement } | Should -Not -Throw
  }
}
