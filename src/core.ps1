
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
Param()

$ErrorActionPreference = "Stop"
."$PSScriptRoot\types.ps1"

$NamespaceDelimiter = ":"

# idempotently applies a requirement
function applyRequirement {
  [CmdletBinding()]
  Param([Requirement]$Requirement)
  switch (("Test", "Set" | ? { $Requirement.$_ }) -join "-") {
    "Test" {
      [RequirementEvent]::new($Requirement, "Test", "Start")
      $testResult = &$Requirement.Test
      [RequirementEvent]::new($Requirement, "Test", "Stop", $testResult)
      if (-not $testResult) {
        Write-Error "Failed to apply Requirement '$($Requirement.Describe)'"
      }
    }
    "Set" {
      [RequirementEvent]::new($Requirement, "Set", "Start")
      $setResult = &$Requirement.Set
      [RequirementEvent]::new($Requirement, "Set", "Stop", $setResult)
    }
    "Test-Set" {
      [RequirementEvent]::new($Requirement, "Test", "Start")
      $testResult = &$Requirement.Test
      [RequirementEvent]::new($Requirement, "Test", "Stop", $testResult)
      if (-not $testResult) {
        [RequirementEvent]::new($Requirement, "Set", "Start")
        $setResult = &$Requirement.Set
        [RequirementEvent]::new($Requirement, "Set", "Stop", $setResult)
        [RequirementEvent]::new($Requirement, "Validate", "Start")
        $validateResult = &$Requirement.Test
        [RequirementEvent]::new($Requirement, "Validate", "Stop", $validateResult)
        if (-not $validateResult) {
          Write-Error "Failed to apply Requirement '$($Requirement.Describe)'"
        }
      }
    }
  }
}

# applies an array of requirements
function applyRequirements([Requirement[]]$Requirements) {
  $Requirements | % { applyRequirement $_ }
}

# run the Test method of a requirement
function testRequirement([Requirement]$Requirement) {
  if ($Requirement.Test) {
    [RequirementEvent]::new($Requirement, "Test", "Start")
    $result = &$Requirement.Test
    [RequirementEvent]::new($Requirement, "Test", "Stop", $result)
  }
}

# tests an array of requirements
function testRequirements([Requirement[]]$Requirements) {
  $Requirements | % { testRequirement $_ }
}

# sorts an array of Requirements in topological order
function sortRequirements([Requirement[]]$Requirements) {
  $stages = @()
  while ($Requirements) {
    $nextStages = $Requirements | ? { -not ($_.DependsOn | ? { $_ -notin $stages.Namespace }) }
    if (-not $nextStages) {
      throw "Could not resolve the dependencies for Requirements with names: $($Requirements.Namespace -join ', ')"
    }
    $Requirements = $Requirements | ? { $_.Namespace -notin $nextStages.Namespace }
    $stages += $nextStages
  }
  $stages
}
