
."$PSScriptRoot\types.ps1"
$ErrorActionPreference = "Stop"

# idempotently applies a requirement
# TODO: logging context
function applyRequirement([Requirement]$Requirement, [LoggingContext]$LoggingContext) {
  $inDesiredState = $false
  if ($Requirement.Test) {
    [RequirementEvent]@{
      Requirement = $Requirement
      Method      = "Test"
      State       = "Begin"
    }
    $result = &$Requirement.Test
    [RequirementEvent]@{
      Requirement = $Requirement
      Method      = "Test"
      State       = "End"
      Result      = $result
    }
  }
  if (-not $inDesiredState) {
    if ($Requirement.Set) {
      [RequirementEvent]@{
        Requirement = $Requirement
        Method      = "Set"
        State       = "Begin"
      }
      $result = &$Requirement.Set
      [RequirementEvent]@{
        Requirement = $Requirement
        Method      = "Set"
        State       = "End"
        Result      = $result
      }
    }
    if ($Requirement.Test -and $Requirement.Set) {
      [RequirementEvent]@{
        Requirement = $Requirement
        Method      = "Validate"
        State       = "Begin"
      }
      $result = &$Requirement.Test
      [RequirementEvent]@{
        Requirement = $Requirement
        Method      = "Validate"
        State       = "End"
        Result      = $result
      }
      if (-not $result) {
        throw "Failed to apply Requirement '$($Requirement.Name)'"
      }
    }
  }
}

# applies an array of requirements
function applyRequirements([Requirement[]]$Requirements, $LoggingContext) {
  $Requirements | % { applyRequirement $_ $LoggingContext }
}

# sorts an array of Requirements in topological order
function sortRequirements([Requirement[]]$Requirements) {
  $stages = @()
  while ($Requirements) {
    $nextStages = $Requirements `
    | ? { -not ($_.DependsOn | ? { $_ -notin $stages.Name }) }
    if (-not $nextStages) {
      throw "Could not resolve the dependencies for Requirements with names: $($Requirements.Name -join ', ')"
    }
    $Requirements = $Requirements | ? { $_.Name -notin $nextStages.Name }
    $stages += $nextStages
  }
  $stages
}
