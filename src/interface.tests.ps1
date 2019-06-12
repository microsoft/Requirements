
$ErrorActionPreference = "Stop"
."$PSScriptRoot\interface.ps1"

$PlatformLacksDscSupport = $PSVersionTable.PSEdition -eq "Core"
if (-not $PlatformLacksDscSupport) {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = $identity.groups -match "S-1-5-32-544"
    if (-not $isAdmin) {
        throw @"
You are running PowerShell 5 and are therefore testing DSC resources.
You must be running as admin to test DSC resources.
"@
    }
}

Describe "New-Requirement" {
    Context "'Script' parameter set" {
        $requirement = @{
            Describe = "My Requirement"
            Test     = { 1 }
            Set      = { 2 }
        }
        It "Should not throw" {
            { New-Requirement @requirement } | Should -Not -Throw
        }
        It "Should not be empty" {
            New-Requirement @requirement | Should -BeTrue
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
            New-Requirement @requirement | Should -BeTrue
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
            $tempFilePath = "$env:TEMP\_dsctest_$(New-Guid).txt"
            $content = "Hello world"
            $params = @{
                Name         = "[file]MyFile"
                Describe     = "My Dsc Requirement"
                ResourceName = "File"
                ModuleName   = "PSDesiredStateConfiguration"
                Property     = @{
                    Contents        = $content
                    DestinationPath = $tempFilePath
                    Force           = $true
                }
            }
            New-Requirement @params | Invoke-Requirement
            Get-Content $tempFilePath | Should -Be $content
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
