
using namespace System.Collections.Generic

$ErrorActionPreference = "Stop"
."$PSScriptRoot\types.ps1"

<#
.SYNOPSIS
  Formats Requirement log events as a live-updating checklist
.NOTES
  Uses Write-Host
#>
function Format-Checklist {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    Param(
        # Logged Requirement lifecycle events
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("Event")]
        [RequirementEvent[]]$RequirementEvent
    )

    begin {
        $lastDescription = ""
    }

    process {
        $timestamp = Get-Date -Date $_.Date -Format 'hh:mm:ss'
        $description = $_.Requirement.Describe
        $method, $state, $result = $_.Method, $_.State, $_.Result
        switch ($method) {
            "Test" {
                switch ($state) {
                    "Start" {
                        $symbol = " "
                        $color = "Yellow"
                        $message = "$timestamp [ $symbol ] $description"
                        Write-Host $message -ForegroundColor $color -NoNewline
                        $lastDescription = $description
                    }
                }
            }
            "Validate" {
                switch ($state) {
                    "Stop" {
                        switch ($result) {
                            $true {
                                $symbol = [char]8730
                                $color = "Green"
                                $message = "$timestamp [ $symbol ] $description"
                                Write-Host "`r$(' ' * $lastDescription.Length)" -NoNewline
                                Write-Host "`r$message" -ForegroundColor $color
                                $lastDescription = $description
                            }
                            $false {
                                $symbol = "X"
                                $color = "Red"
                                $message = "$timestamp [ $symbol ] $description"
                                Write-Host "`n$message`n" -ForegroundColor $color
                                $lastDescription = $description
                                exit -1
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
