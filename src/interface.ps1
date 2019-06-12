
$ErrorActionPreference = "Stop"
."$PSScriptRoot\core.ps1"
."$PSScriptRoot\formatters.ps1"

function New-Requirement {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [OutputType([Requirement])]
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName = "Script")]
        [Parameter(ParameterSetName = "Dsc")]
        [string] $Name,
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [Parameter(Mandatory, ParameterSetName = "Dsc")]
        [string] $Describe,
        [Parameter(ParameterSetName = "Script")]
        [scriptblock] $Test,
        [Parameter(ParameterSetName = "Script")]
        [scriptblock] $Set,
        [Parameter(ParameterSetName = "Script")]
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
        "Script" {
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
        [Requirement[]] $Requirement
    )

    applyRequirements (sortRequirements $input)
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
