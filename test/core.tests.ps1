
$ErrorActionPreference = "Stop"

$RepoRoot = "$PSScriptRoot/.."
$SourceRoot = "$RepoRoot/src"
."$SourceRoot\core.ps1"

Describe "Core" {
    Context "applyRequirement" {
        It "Should not 'Set' if in desired state" {
            $script:NotSetIfInDesiredState = 0
            applyRequirement @{
                Describe = "Simple Requirement"
                Test     = { $true }
                Set      = { $script:NotSetIfInDesiredState++ }
            }
            $script:NotSetIfInDesiredState | Should -Be 0
        }
        It "Should 'Set' if not in desired state" {
            $script:SetIfNotInDesiredState = 0
            applyRequirement @{
                Describe = "Simple Requirement"
                Test     = { $script:SetIfNotInDesiredState -eq 1 }
                Set      = { $script:SetIfNotInDesiredState++ }
            }
            $script:SetIfNotInDesiredState | Should -Be 1
        }
        It "Should validate once set" {
            $script:TestOnceSetIsTestCount = 0
            $script:TestOnceSetIsSet = $false
            applyRequirement @{
                Describe = "Simple Requirement"
                Test     = { $script:TestOnceSetIsTestCount += 1; $script:TestOnceSetIsSet }
                Set      = { $script:TestOnceSetIsSet = $true }
            }
            $script:TestOnceSetIsSet | Should -Be $true
            $script:TestOnceSetIsTestCount | Should -Be 2
        }
        It "Should 'Set' if no 'Test' is provided" {
            $script:SetIfNoTest = $false
            applyRequirement @{
                Describe = "Simple Requirement"
                Set      = { $script:SetIfNoTest = $true }
            }
            $script:SetIfNoTest | Should -BeTrue
        }
        It "Should not 'Test' if no 'Set' is provided" {
            $script:NotTestIfNoSet = 0
            applyRequirement @{
                Describe = "Simple Requirement"
                Test     = { $script:NotTestIfNoSet++ }
            }
            $script:NotTestIfNoSet | Should -Be 1
        }
        It "Should output all log events" {
            $script:SetIfNotInDesiredState = 0
            $events = applyRequirement @{
                Describe = "Simple Requirement"
                Test     = { $script:SetIfNotInDesiredState -eq 1 }
                Set      = { $script:SetIfNotInDesiredState++ }
            }
            $expectedIds = "Test", "Set", "Validate" | % { "$_-Start", "$_-Stop" }
            $foundIds = $events | % { "$($_.Method)-$($_.State)" }
            $expectedIds | % { $_ -in $foundIds | Should -BeTrue }
        }
        It "Should provide the result of the 'Test'" {
            $expected = "This string should be the result of the 'Test' block"
            $event = applyRequirement @{
                Describe = "Simple Requirement"
                Test     = { $expected }
            }
            $event | Select -First 1 -Skip 1 | % Result | Should -Be $expected
        }
        It "Should provide the result of the 'Set'" {
            $expected = "This string should be the result of the 'Set' block"
            $event = applyRequirement @{
                Describe = "Simple Requirement"
                Set      = { $expected }
            }
            $event | Select -First 1 -Skip 1 | % Result | Should -Be $expected
        }
    }
    Context "applyRequirements" {
        It "Should call 'Test' on each requirement" {
            $script:CallTestOnEachRequirement = 0
            $requirements = 1..3 | % {
                @{
                    Describe = "Simple Requirement"
                    Test     = { $script:CallTestOnEachRequirement++ % 2 }
                    Set      = { $false }
                }
            }
            applyRequirements $requirements
            $script:CallTestOnEachRequirement | Should -Be 6
        }
    }
}
