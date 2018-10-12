# TODO: (MEDIUM) Implement cmdlets wrapping the class implementation
# TODO: (MEDIUM) Break out Configuration\ConfigurationManager into Modules\ConfigurationManager
# TODO: (MEDIUM) Ensure stack traces propogate from module functions

using namespace System.Collections.Generic

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

$LogContext = [Stack[string]]::new()


Import-Module "Profile"



$DockerLinePrefix = " ----->"


function Write-Log {
    Param(
        [Parameter(Mandatory, Position=0, ParameterSetName="PushContext")]
        [Parameter(Mandatory, Position=0, ParameterSetName="ExistingContext")]
        [string] $Context,
        [Parameter(Mandatory, Position=1, ParameterSetName="PushContext")]
        [scriptblock] $ScriptBlock
    )

    switch ($PSCmdlet.ParameterSetName) {
        "PushContext" {
            $LogContext.Push($Context)
            Write-Log "<begin>"
            $result = &$ScriptBlock
            Write-Log "<end>"
            $LogContext.Pop() | Out-Null
            if ($result -is [object]) {
                return $result
            } else {
                return $null
            }
        }

        "ExistingContext" {
            $stack = $LogContext.ToArray()
            [array]::Reverse($stack)
            $prefix = "$DockerLinePrefix $(Get-Date -Format "hh:mm:ss") [$($stack -join " > ")]"
            Write-Information "$prefix $Context"
        }

    }
}


function Invoke-ContextRequirement {
    Param(
        [string]$Name,
        [scriptblock]$Test,
        [scriptblock]$Set
    )

    try {
        Write-Log $Name {

            $requirementAlreadyMet = Write-Log "Test" {&$Test}
            if (-not $requirementAlreadyMet) {
                Write-Log "Set" {&$Set | Out-Null}
                $requirementValidated = Write-Log "Test" {&$Test}
                if (-not $requirementValidated) {
                    throw "Requirement validation failed"
                }
            }

        }
    }
    catch {
        Write-Error $_.Exception
    }
}



function Invoke-ContextDscRequirement {
    Param(
        [string]$Name,
        [string]$ResourceName,
        [string]$ModuleName,
        [hashtable]$Property
    )

    $dscParams = @{
        Name       = $ResourceName
        ModuleName = $ModuleName
        Property   = $Property
    }

    Invoke-Requirement `
        -Name $Name `
        -Test {Invoke-DscResource -Method "Test" @dscParams} `
        -Set {Invoke-DscResource -Method "Set" @dscParams}

}
