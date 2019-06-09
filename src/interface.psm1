
$ErrorActionPreference = "Stop"
."$PSScriptRoot\core.ps1"

function New-Requirement {
  [OutputType([Requirement])]
  Param(
    [Parameter(ParameterSetName = "ApplyIfNeeded")]
    [Parameter(ParameterSetName = "Dsc")]
    [string] $Name,
    [Parameter(Mandatory, ParameterSetName = "ApplyIfNeeded")]
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [string] $Describe,
    [Parameter(Mandatory, ParameterSetName = "ApplyIfNeeded")]
    [ValidateNotNullOrEmpty()]
    [scriptblock] $Test,
    [Parameter(Mandatory, ParameterSetName = "ApplyIfNeeded")]
    [ValidateNotNullOrEmpty()]
    [scriptblock] $Set,
    [Parameter(ParameterSetName = "ApplyIfNeeded")]
    [Parameter(ParameterSetName = "Dsc")]
    [ValidateNotNull()]
    [string[]] $DependsOn = @(),
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceName,
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleName,
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [ValidateNotNullOrEmpty()]
    [hashtable]$Property
  )

  switch ($PSCmdlet.ParameterSetName) {
    "ApplyAlways" {
      $vars = @{hasRun = $false }
      [Requirement]@{
        Name      = $Name
        Describe  = $Describe
        Test      = { $hasRun }
        Set       = {
          $vars["hasRun"] = $true
          &$Set
        }
        DependsOn = $DependsOn
      }
    }
    "ApplyIfNeeded" {
      [Requirement]@{
        Name      = $Name
        Describe  = $Describe
        Test      = $Test
        Set       = $Set
        DependsOn = $DependsOn
      }
    }
    "Dsc" {
      $dscParams = @{
        Name       = $ResourceName
        ModuleName = $ModuleName
        Property   = $Property
      }
      [Requirement]@{
        Name      = $Name
        Describe  = $Describe
        Test      = { Invoke-DscResource -Method "Test" @dscParams }
        Set       = { Invoke-DscResource -Method "Set" @dscParams }
        DependsOn = $DependsOn
      }
    }
  }
}

function Invoke-Requirement {
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNull()]
    [Requirement[]] $Requirement
  )

  typeAssertLoggingContext $loggingContext
  applyRequirements (sortRequirements $Requirement) $loggingContext
}

function Test-Requirement {
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [Requirement] $Requirement
  )

  &$Requirement.Test
}

function Set-Requirement {
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [Requirement] $Requirement
  )

  &$Requirement.Set
}
