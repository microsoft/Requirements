
$ErrorActionPreference = "Stop"
."$PSScriptRoot\types.ps1"

# idempotently applies a requirement
function applyRequirement([Requirement]$Requirement) {
    $result = $false
    if ($Requirement.Test) {
        [RequirementEvent]::new($Requirement, "Test", "Start")
        $result = &$Requirement.Test
        [RequirementEvent]::new($Requirement, "Test", "Stop", $result)
    }
    if (-not $result) {
        if ($Requirement.Set) {
            [RequirementEvent]::new($Requirement, "Set", "Start")
            $result = &$Requirement.Set
            [RequirementEvent]::new($Requirement, "Set", "Stop", $result)
        }
        if ($Requirement.Test -and $Requirement.Set) {
            [RequirementEvent]::new($Requirement, "Validate", "Start")
            $result = &$Requirement.Test
            [RequirementEvent]::new($Requirement, "Validate", "Stop", $result)
            if (-not $result) {
                Write-Error "Failed to apply Requirement '$($Requirement.Name)'"
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
