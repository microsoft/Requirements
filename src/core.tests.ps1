
."$PSScriptRoot\types.ps1"
."$PSScriptRoot\core.ps1"

class EmptyLoggingContext {
  [void] BeginPrecheck() {

  }
  [void] EndPrecheck([boolean] $inDesiredState) {

  }
  [void] BeginSet() {

  }
  [void] EndSet() {

  }
  [void] BeginValidate() {

  }
  [void] EndValidate([boolean] $validated) {

  }
}

Describe "Core" {
  Context "applyRequirement" {
    It "Should not 'Set' if in desired state" {
      $script:NotSetIfInDesiredState = 0
      applyRequirement -LoggingContext ([EmptyLoggingContext]::new()) -Requirement @{
        Describe = "Simple Requirement"
        Test     = { $true }
        Set      = { $script:NotSetIfInDesiredState++ }
      }
      $script:NotSetIfInDesiredState | Should -Be 0
    }
    It "Should 'Set' if not in desired state" {
      $script:SetIfNotInDesiredState = 0
      applyRequirement -LoggingContext ([EmptyLoggingContext]::new()) -Requirement @{
        Describe = "Simple Requirement"
        Test     = { $script:SetIfNotInDesiredState -eq 1 }
        Set      = { $script:SetIfNotInDesiredState++ }
      }
      $script:SetIfNotInDesiredState | Should -Be 1
    }
    It "Should validate once set" {
      $script:TestOnceSetIsTestCount = 0
      $script:TestOnceSetIsSet = $false
      applyRequirement -LoggingContext ([EmptyLoggingContext]::new()) -Requirement @{
        Describe = "Simple Requirement"
        Test     = { $script:TestOnceSetIsTestCount += 1; $script:TestOnceSetIsSet }
        Set      = { $script:TestOnceSetIsSet = $true }
      }
      $script:TestOnceSetIsSet | Should -Be $true
      $script:TestOnceSetIsTestCount | Should -Be 2
    }
    It "Should 'Set' if no 'Test' is provided" {
      $script:SetIfNoTest = $false
      applyRequirement -LoggingContext ([EmptyLoggingContext]::new()) -Requirement @{
        Describe = "Simple Requirement"
        Set      = { $script:SetIfNoTest = $true }
      }
      $script:SetIfNoTest | Should -BeTrue
    }
    It "Should not 'Test' if no 'Set' is provided" {
      $script:NotTestIfNoSet = 0
      applyRequirement -LoggingContext ([EmptyLoggingContext]::new()) -Requirement @{
        Describe = "Simple Requirement"
        Test     = { $script:NotTestIfNoSet++ }
      }
      $script:NotTestIfNoSet | Should -Be 1
    } 
    It "Should correctly use a logging context" {

    }
  }
  Context "applyRequirements" {
    It "Should call 'Test' on each requirement" {
      $script:CallTestOnEachRequirement = 0
      $requirements = 1..3 | % { 
        @{
          Name     = $_
          Describe = "Simple Requirement"
          Test     = { $script:CallTestOnEachRequirement++ % 2 }
          Set      = { $false }
        }
      }
      applyRequirements $requirements
      $script:CallTestOnEachRequirement | Should -Be 6
    }
  }
  Context "sortRequirements" {
    It "Should sort an array of requirements into topological order" {
      $sorted = sortRequirements @(
        @{
          Name      = "third"
          Describe  = "Simple Requirement"
          Test      = { }
          Set       = { }
          DependsOn = "first", "second"
        },
        @{
          Name     = "first"
          Describe = "Simple Requirement"
          Test     = { }
          Set      = { }
        },
        @{
          Name      = "second"
          Describe  = "Simple Requirement"
          Test      = { }
          Set       = { }
          DependsOn = "first"
        }
      )
      [string[]]$names = $sorted | % Name
      0..($sorted.Count - 1) | % {
        $i, $requirement = $_, $sorted[$_]
        $requirement.DependsOn `
        | % { $names.IndexOf($_) | Should -BeLessThan $i }
      }
    }
    It "Should throw an error if there are unresolvable dependencies" {
      {
        sortRequirements @(
          @{
            Name      = "third"
            Describe  = "Simple Requirement"
            Test      = { }
            Set       = { }
            DependsOn = "first", "second"
          },
          @{
            Name     = "first"
            Describe = "Simple Requirement"
            Test     = { }
            Set      = { }
          },
          @{
            Name      = "second"
            Describe  = "Simple Requirement"
            Test      = { }
            Set       = { }
            DependsOn = "first", "third"
          }
        )
      } | Should -Throw
    }
  }
  Context "typeAssertLoggingContext" {
    It "Should throw an error if not all methods are defined" {
      class TestLogger {
        [void] beginPrecheck() { }
        [void] endPrecheck() { }
        [void] beginSet() { }
        [void] endSet() { }
        [void] endPostcheck() { }
      }
      $logger = [TestLogger]::new()
      { typeAssertLoggingContext $logger } | Should -Throw
    }
    It "Should not throw an error if all methods are defined" {
      class TestLogger {
        [void] beginPrecheck() { }
        [void] endPrecheck() { }
        [void] beginSet() { }
        [void] endSet() { }
        [void] beginPostcheck() { }
        [void] endPostcheck() { }
      }
      $logger = [TestLogger]::new()
      { typeAssertLoggingContext $logger } | Should -Not -Throw
    }
  }
}
