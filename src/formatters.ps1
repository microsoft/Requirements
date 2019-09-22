
using namespace System.Collections.Generic

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
Param()

$ErrorActionPreference = "Stop"
."$PSScriptRoot\types.ps1"

function writePending($timestamp, $description) {
    $symbol = " "
    $color = "Yellow"
    $message = "$timestamp [ $symbol ] $description"
    Write-Host $message -ForegroundColor $color -NoNewline
}

function writeSuccess($timestamp, $description, $clearString) {
    $symbol = [char]8730
    $color = "Green"
    $message = "$timestamp [ $symbol ] $description"
    Write-Host "`r$clearString" -NoNewline
    Write-Host "`r$message" -ForegroundColor $color
}

function writeFail($timestamp, $description, $clearString) {
    $symbol = "X"
    $color = "Red"
    $message = "$timestamp [ $symbol ] $description"
    Write-Host "`r$clearString" -NoNewline
    Write-Host "`n$message`n" -ForegroundColor $color
    exit -1
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
        $description = $requirement.Describe
        $clearString = ' ' * "??:??:?? [ ? ] $($previousRequirement.Describe)".Length
        $transitionArgs = @($timestamp, $description, $clearString)

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

<#
.SYNOPSIS
  Formats every log event with metadata, including a stack of requirement names when using nested Requirements
.NOTES
  Uses Write-Host
#>
function Format-CallStack {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    Param(
        # Logged Requirement lifecycle events
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("Event")]
        [RequirementEvent[]]$RequirementEvent
    )

    begin {
        $context = [Stack[string]]::new()
    }

    process {
        $timestamp = Get-Date -Date $_.Date -Format 'hh:mm:ss'
        $name = $_.Requirement.Name
        $description = $_.Requirement.Describe
        $method, $state, $result = $_.Method, $_.State, $_.Result
        switch ($method) {
            "Test" {
                switch ($state) {
                    "Start" {
                        $context.Push($name)
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$timestamp [$serialized] BEGIN TEST $description"
                    }
                    "Stop" {
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$timestamp [$serialized] END TEST => $result"
                        $context.Pop() | Out-Null
                    }
                }
            }
            "Set" {
                switch ($state) {
                    "Start" {
                        $context.Push($name)
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$timestamp [$serialized] BEGIN SET $description"
                    }
                    "Stop" {
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$timestamp [$serialized] END SET"
                        $context.Pop() | Out-Null
                    }
                }
            }
            "Validate" {
                switch ($state) {
                    "Start" {
                        $context.Push($name)
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$timestamp [$serialized] BEGIN TEST $description"
                    }
                    "Stop" {
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$timestamp [$serialized] END TEST => $result"
                        $context.Pop() | Out-Null
                    }
                }
            }
        }
    }
}
