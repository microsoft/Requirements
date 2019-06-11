
$ErrorActionPreference = "Stop"
."$PSScriptRoot\core.ps1"

function New-Requirement {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
  [CmdletBinding()]
  [OutputType([Requirement])]
  Param(
    [Parameter(ParameterSetName = "ApplyAlways")]
    [Parameter(ParameterSetName = "ApplyIfNeeded")]
    [Parameter(ParameterSetName = "Dsc")]
    [string] $Name,
    [Parameter(Mandatory, ParameterSetName = "ApplyAlways")]
    [Parameter(Mandatory, ParameterSetName = "ApplyIfNeeded")]
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [string] $Describe,
    [Parameter(ParameterSetName = "ApplyIfNeeded")]
    [scriptblock] $Test,
    [Parameter(ParameterSetName = "ApplyAlways")]
    [Parameter(ParameterSetName = "ApplyIfNeeded")]
    [scriptblock] $Set,
    [Parameter(ParameterSetName = "ApplyAlways")]
    [Parameter(ParameterSetName = "ApplyIfNeeded")]
    [Parameter(ParameterSetName = "Dsc")]
    [ValidateNotNull()]
    [string[]] $DependsOn = @(),
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [string]$ResourceName,
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [string]$ModuleName,
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
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
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNull()]
    [Requirement[]] $Requirement
  )

  applyRequirements (sortRequirements $Requirement)
}

function Test-Requirement {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [Requirement] $Requirement
  )

  &$Requirement.Test
}

function Set-Requirement {
  [CmdletBinding(SupportsShouldProcess)]
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [Requirement] $Requirement
  )

  if ($PSCmdlet.ShouldProcess($Requirement, "Set")) {
    &$Requirement.Set
  }
}
