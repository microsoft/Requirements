
using namespace System.Collections.Generic

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
Param()

$ErrorActionPreference = "Stop"
."$PSScriptRoot\types.ps1"

function writePending($timestamp, $requirement) {
    $symbol = " "
    $color = "Yellow"
    $message = "$symbol $timestamp $requirement"
    Write-Host $message -ForegroundColor $color -NoNewline
}

function writeSuccess($timestamp, $requirement, $clearString) {
    $symbol = [char]8730
    $color = "Green"
    $message = "$symbol $timestamp $requirement"
    Write-Host "`r$clearString" -NoNewline
    Write-Host "`r$message" -ForegroundColor $color
}

function writeFail($timestamp, $requirement, $clearString) {
    $symbol = "X"
    $color = "Red"
    $message = "$symbol $timestamp $requirement"
    Write-Host "`r$clearString" -NoNewline
    Write-Host "`n$message`n" -ForegroundColor $color
}

$fsm = @{
    "Test Test Start $false"    = {
        writePending @args
        @{
            "Test Test Stop $true"  = {
                writeSuccess @args
                $fsm
            }
            "Test Test Stop $false" = {
                writeFail @args
            }
        }
    }
    "Set Set Start *"           = {
        writePending @args
        @{
            "Set Set Stop *" = {
                writeSuccess @args
                $fsm
            }
        }
    }
    "TestSet Test Start $false" = {
        writePending @args
        @{
            "TestSet Test Stop $true"  = {
                writeSuccess @args
                $fsm
            }
            "TestSet Test Stop $false" = {
                @{
                    "TestSet Set Start *" = {
                        @{
                            "TestSet Set Stop *" = {
                                @{
                                    "TestSet Validate Start $false" = {
                                        @{
                                            "TestSet Validate Stop $true"  = {
                                                writeSuccess @args
                                                $fsm
                                            }
                                            "TestSet Validate Stop $false" = {
                                                writeFail @args
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

<#
.SYNOPSIS
  Formats Requirement log events as a live-updating checklist
.NOTES
  Uses Write-Host
#>
function Format-Checklist {
    [CmdletBinding()]
    Param(
        # Logged Requirement lifecycle events
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("Event")]
        [RequirementEvent[]]$RequirementEvent
    )

    begin {
        $previousRequirement = $null
        $nextFsm = $fsm
    }

    process {
        $requirement = $_.Requirement

        # build state vector
        $requirementType = ("Test", "Set" | ? { $requirement.$_ }) -join ""
        $method = $_.Method
        $lifecycleState = $_.State
        $successResult = if ($method -eq "Set") { "*" } else { [bool]$_.Result }
        $stateVector = "$requirementType $method $lifecycleState $successResult"

        # build transition arguments
        $timestamp = Get-Date -Date $_.Date -Format "hh:mm:ss"
        $clearString = ' ' * "? ??:??:?? $previousRequirement".Length
        $transitionArgs = @($timestamp, $requirement, $clearString)

        # transition FSM
        if (-not $nextFsm[$stateVector]) {
            throw @"
Format-Checklist has reached an unexpected state '$stateVector'.
If you are piping the output of Invoke-Requirement directly to this
cmdlet, then this is probably a bug in Format-Checklist.
"@
        }
        $nextFsm = &$nextFsm[$stateVector] @transitionArgs
        $previousRequirement = $requirement
    }
}

function Format-Verbose {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        # Logged Requirement lifecycle events
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("Event")]
        [RequirementEvent[]]$RequirementEvent
    )

    process {
        $timestamp = Get-Date -Date $_.Date -Format 'yyyy-MM-dd HH:mm:ss'
        "{0} {1,-8} {2,-5} {3}" -f $timestamp, $_.Method, $_.State, $_.Requirement
    }
}
