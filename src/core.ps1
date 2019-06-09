
using namespace System.Collections;

."$PSScriptRoot\types.ps1"
$ErrorActionPreference = "Stop"

$LoggingContextMethods = "BeginPrecheck", "EndPrecheck", "BeginSet", "EndSet", "BeginPostcheck", "EndPostcheck"

# idempotently applies a requirement
# TODO: logging context
function applyRequirement([Requirement]$Requirement, [LoggingContext]$LoggingContext) {
  $inDesiredState = $false
  if ($Requirement.Test) {
    $LoggingContext.BeginPrecheck()
    $inDesiredState = &$Requirement.Test
    $LoggingContext.EndPrecheck($inDesiredState)
  }
  if (-not $inDesiredState) {
    if ($Requirement.Set) {
      $LoggingContext.BeginSet()
      &$Requirement.Set
      $LoggingContext.EndSet()
    }
    if ($Requirement.Test -and $Requirement.Set) {
      $LoggingContext.BeginPostcheck()
      $validated = &$Requirement.Test
      $LoggingContext.EndPostcheck($validated)
      if (-not $validated) {
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

# ensure logging context implements the logging context interface (pwsh doesn't support interfaces)
function typeAssertLoggingContext($loggingContext) {
  $missingMethods = $LoggingContextMethods | ? { -not $loggingContext.$_ }
  if ($missingMethods) {
    throw "Logging Context does not contain method definitions for $($missingMethods -join ', ')"
  }
}
