<##

#>

using namespace System.Collections.Generic

$ErrorActionPreference = "Stop"
."$PSScriptRoot\types.ps1"

<#
.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
function Format-Checklist {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    Param(
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
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
function Format-CallStack {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("Event")]
        [RequirementEvent[]]$RequirementEvent,
        [switch]$Measure
    )

    begin {
        $context = [Stack[string]]::new()
    }

    process {
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
                        Write-Host "$($_.Date) [$serialized] BEGIN TEST $description"
                    }
                    "Stop" {
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$($_.Date) [$serialized] END TEST => $result"
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
                        Write-Host "$($_.Date) [$serialized] BEGIN SET $description"
                    }
                    "Stop" {
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$($_.Date) [$serialized] END SET"
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
                        Write-Host "$($_.Date) [$serialized] BEGIN TEST $description"
                    }
                    "Stop" {
                        $callstack = $context.ToArray()
                        [array]::Reverse($callstack)
                        $serialized = $callstack -join ">"
                        Write-Host "$($_.Date) [$serialized] END TEST => $result"
                        $context.Pop() | Out-Null
                    }
                }
            }
        }
    }
}
