
Import-Module Pester
Import-Module .\Requirements


Describe "Invoke-ChecklistRequirement" {

    It "Should write to host correctly" {
        # convert Host stream to array by writing to then reading from file
        $tempFile = "$env:TEMP\$(New-Guid).out.txt"
        try {
            Invoke-ChecklistRequirement `
                -Describe "Simple Requirement" `
                -Test { $script:ValidRequirementHasRun } `
                -Set { $script:ValidRequirementHasRun = $true } `
                *> $tempFile
            $output = Get-Content $tempFile
            $loggedOutput = $output | ? {$_.Trim()}
            $clearedOutput = $output | ? {-not $_.Trim()}
            $loggedOutput | % {$_ | Should -Match "^\d\d:\d\d:\d\d \[ . \] Simple Requirement$"}
            $clearedOutput.Count | Should -Be 1
            $loggedOutput.Count | Should -Be 2
        } finally {
            Remove-Item $tempFile
        }
    }

    It "Should not 'Set' if in desired state" {
        $script:NotSetIfInDesiredState = 0
        Invoke-ChecklistRequirement `
            -Describe "Simple Requirement" `
            -Test { $true } `
            -Set { $script:NotSetIfInDesiredState++ } `
            *> $null
        $script:NotSetIfInDesiredState | Should -Be 0
    }

    It "Should 'Set' if in desired state" {
        $script:SetIfInDesiredState = 0
        Invoke-ChecklistRequirement `
            -Describe "Simple Requirement" `
            -Test {$script:SetIfInDesiredState -gt 0} `
            -Set {$script:SetIfInDesiredState++} `
            *> $null
        $script:SetIfInDesiredState | Should -Be 1
    }

    It "Should validate once set" {
        $script:TestOnceSetIsTestCount = 0
        $script:TestOnceSetIsSet = $false
        Invoke-ChecklistRequirement `
            -Describe "Simple Requirement" `
            -Test {$script:TestOnceSetIsTestCount += 1; $script:TestOnceSetIsSet} `
            -Set {$script:TestOnceSetIsSet = $true} `
            *> $null
        $script:TestOnceSetIsSet | Should -Be $true
        $script:TestOnceSetIsTestCount | Should -Be 2
    }

}
