<##

#>

using namespace System.Collections.Generic

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

  process {
    $timestamp = Get-Date -Date $_.Requirement.Date -Format 'hh:mm:ss'
    $description = $_.Requirement.Description
    switch ($_.Method) {
      "Test" {
        switch ($_.State) {
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
        switch ($_.State) {
          "Stop" {
            switch ([boolean]$_.Result) {
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
    $result = $_.Requirement.Result
    $timestamp = $_.Date
    $stack = $context.ToArray() -join ">"
    Write-Host "$timestamp [$stack] " -NoNewline
    switch ($_.Method) {
      "Test" {
        switch ($_.State) {
          "Start" {
            $context.Push($name)
            Write-Host "BEGIN TEST $description"
          }
          "Stop" {
            $context.Pop()
            Write-Host "END TEST => $result"
          }
        }
      }
      "Set" {
        switch ($_.State) {
          "Start" {
            $context.Push($name)
            Write-Host "BEGIN SET $description"
          }
          "Stop" {
            $context.Pop()
            Write-Host "END SET"
          }
        }
      }
      "Validate" {
        switch ($_.State) {
          "Start" {
            $context.Push($name)
            Write-Host "BEGIN TEST $description"
          }
          "Stop" {
            $context.Pop()
            Write-Host "END TEST => $result"
          }
        }
      }
    }
  }
}
