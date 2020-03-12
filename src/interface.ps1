
$ErrorActionPreference = "Stop"
."$PSScriptRoot\core.ps1"
."$PSScriptRoot\formatters.ps1"

<#
.SYNOPSIS
    Creates a new Requirement object
.OUTPUTS
    The resulting Requirement
.NOTES
    Dsc parameter set is unsupported due to cross-platform limitations
#>
function New-Requirement {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
  [OutputType([Requirement])]
  [CmdletBinding()]
  Param(
    # The unique identifier for the Requirement
    [Parameter(ParameterSetName = "Script")]
    [Parameter(ParameterSetName = "Dsc")]
    [string] $Namespace,
    # A description of the Requirement
    [Parameter(Mandatory, ParameterSetName = "Script")]
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [string] $Describe,
    # The Test condition that determines if the Requirement is in its desired state
    [Parameter(ParameterSetName = "Script")]
    [scriptblock] $Test,
    # The Set condition that Sets the Requirement to its desired state
    [Parameter(ParameterSetName = "Script")]
    [scriptblock] $Set,
    # The list of Requirement Names that must be in desired state prior to this Requirement
    [Parameter(ParameterSetName = "Script")]
    [Parameter(ParameterSetName = "Dsc")]
    [ValidateNotNull()]
    [string[]] $DependsOn = @(),
    # The name of the DSC resource associated with the Requirement
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceName,
    # The module containing the DSC resource
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleName,
    # The properties passed through to the DSC resource
    [Parameter(Mandatory, ParameterSetName = "Dsc")]
    [ValidateNotNullOrEmpty()]
    [hashtable]$Property
  )

  switch ($PSCmdlet.ParameterSetName) {
    "Script" {
      [Requirement]@{
        Namespace = $Namespace
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
        Namespace = $Namespace
        Describe  = $Describe
        Test      = { Invoke-DscResource -Method "Test" @dscParams }.GetNewClosure()
        Set       = { Invoke-DscResource -Method "Set" @dscParams }.GetNewClosure()
        DependsOn = $DependsOn
      }
    }
  }
}

<#
.SYNOPSIS
    Sets Requirements to their desired states
.OUTPUTS
    The RequirementEvents logged from each stage of the Requirement lifecycle
#>
function Invoke-Requirement {
  [CmdletBinding()]
  [OutputType([RequirementEvent])]
  Param(
    # The Requirements to put in their desired state
    [Parameter(Mandatory, ValueFromPipeline)]
    [Requirement[]] $Requirement
  )

  applyRequirements (sortRequirements $input)
}

<#
.SYNOPSIS
    Tests whether a requirement is in its desired state
#>
function Test-Requirement {
  [CmdletBinding()]
  Param(
    # The Requirement to test its desired state
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [Requirement[]] $Requirement
  )

  testRequirements (sortRequirements $input)
}

<#
.SYNOPSIS
    Sets the requirement to its desired state
#>
function Set-Requirement {
  [CmdletBinding(SupportsShouldProcess)]
  Param(
    # The Requirement that sets if its in its desired state
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [Requirement] $Requirement
  )

  if ($PSCmdlet.ShouldProcess($Requirement, "Set")) {
    &$Requirement.Set
  }
}

<#
.SYNOPSIS
    Creates a Group of Requirements
#>
function New-RequirementGroup {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
  [CmdletBinding()]
  [Alias("Push-Namespace")]
  Param(
    # The namespace identifier
    [Parameter(Mandatory, Position = 0)]
    [Alias("Namespace")]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    # A scriptblock that writes Requirements to output when invoked
    [Parameter(Mandatory, Position = 1, ParameterSetName = "scriptblock")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,
    # The array of Requirements to add under the new Group
    [Parameter(Mandatory, Position = 1, ParameterSetName = "requirements")]
    [ValidateNotNullOrEmpty()]
    [Requirement[]]$Requirement
  )

  if ($PSCmdlet.ParameterSetName -eq "scriptblock") {
    $Requirement = &$ScriptBlock
  }

  $Requirement `
  | % {
    $r = $_.psobject.Copy()
    $r.Namespace = ($Name, $r.Namespace | ? { $_ }) -join $NamespaceDelimiter
    $r
  }
}
