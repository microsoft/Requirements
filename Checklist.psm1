
enum Status {
    NotRun
    Pass
    Fail
}



class Log {

    # We originally used [Status] values as keys instead of casting [Status] values to strings.
    # We cast values to strings for now due to a bug in PSScriptAnalyzer v1.16.1
    static [hashtable] $Symbols = @{
        Pass   = [char]8730
        Fail   = "X"
        NotRun = " "
    }
    static [hashtable] $Colors = @{
        Pass   = "Green"
        NotRun = "Yellow"
        Fail   = "Red"
    }
    static [int] $LastLineLength

    static [void] WriteLine([string] $message, [Status] $status) {
        $message = [Log]::FormatMessage($message, $status)
        [Log]::LastLineLength = $message.Length
        $color = [Log]::Colors[ [string]$status ]
        Write-Host $message -ForegroundColor $color -NoNewline
    }

    static [void] OverwriteLine([string] $message, [Status] $status) {
        Write-Host "`r$(' ' * [Log]::LastLineLength)" -NoNewline
        $message = [Log]::FormatMessage($message, $status)
        [Log]::LastLineLength = $message.Length
        $color = [Log]::Colors[ [string]$status ]
        Write-Host "`r$message" -ForegroundColor $color
    }

    static [string] FormatMessage([string] $message, [Status] $status) {
        $symbol = [Log]::Symbols[ [string]$status ]
        return "$(Get-Date -Format 'hh:mm:ss') [ $symbol ] $message"
    }

    static [void] WriteError([string] $message) {
        Write-Host "`n$message`n" -ForegroundColor Red
        exit -1
    }
}





<#
.SYNOPSIS
Ensures a requirement is met.

.DESCRIPTION
This cmdlet allows for declaratively defining requirements and implementing consistent logging and idempotency around the status of the requirements.

.PARAMETER Describe
A description of the requirement that is enforced.

.PARAMETER Test
If present, 'Test' is a scriptblock that returns 'true' if the requirement is already met and the 'Set' scriptblock should not run.  If not present, 'Set' will always run.

.PARAMETER Set
A scriptblock that imposes the requirement when run.  If a "Test' scriptblock is not provided, 'Set' must be idempotent.

.PARAMETER Message
An error message printed if an idempotent 'Set' scriptblock fails during execution.

.EXAMPLE
# A non-idempotent 'Set' scriptblock
Invoke-ChecklistRequirement `
    -Describe "'Hello world' is logged" `
    -Test {Get-Content $MyLogFilePath | ? {$_ -eq "Hello world"}} `
    -Set {"Hello world" >> $MyLogFilePath}

# An idempotent 'Set' scriptblock
Invoke-ChecklistRequirement `
    -Describe "'Hello world' is logged" `
    -Set {"Hello world" > $MyLogFilePath} `
    -Message "Could not log 'Hello World'"
#>
function Invoke-ChecklistRequirement {
    Param(
        [Parameter(Mandatory, ParameterSetName = "ApplyIfNeeded")]
        [Parameter(Mandatory, ParameterSetName = "ApplyAlways")]
        [Parameter(Mandatory, ParameterSetName = "Information")]
        [ValidateNotNullOrEmpty()]
        [string] $Describe,
        [Parameter(Mandatory, ParameterSetName = "ApplyIfNeeded")]
        [ValidateNotNullOrEmpty()]
        [scriptblock] $Test,
        [Parameter(Mandatory, ParameterSetName = "ApplyIfNeeded")]
        [Parameter(Mandatory, ParameterSetName = "ApplyAlways")]
        [ValidateNotNullOrEmpty()]
        [scriptblock] $Set,
        [Parameter(Mandatory, ParameterSetName = "ApplyAlways")]
        [ValidateNotNullOrEmpty()]
        [string] $Message,
        [switch] $ListRequirement
    )


    try {

        if ($ListRequirement) {
            [Log]::WriteLine("$Describe`n", [Status]::NotRun)
            return
        }

        switch ($PSCmdlet.ParameterSetName) {

            "ApplyIfNeeded" {
                [Log]::WriteLine($Describe, [Status]::NotRun)
                if (&$Test) {
                    [Log]::OverwriteLine($Describe, [Status]::Pass)
                }
                else {
                    &$Set | Out-Null
                    if (&$Test) {
                        [Log]::OverwriteLine($Describe, [Status]::Pass)
                    }
                    else {
                        [Log]::OverwriteLine($Describe, [Status]::Fail)
                        [Log]::WriteError("Requirement validation failed")
                    }
                }
            }

            "ApplyAlways" {
                [Log]::WriteLine($Describe, [Status]::NotRun)
                if (&$Set) {
                    [Log]::OverwriteLine($Describe, [Status]::Pass)
                }
                else {
                    [Log]::OverwriteLine($Describe, [Status]::Fail)
                    [Log]::WriteError($Message)
                }
            }

            "Information" {
                [Log]::WriteLine("$Describe`n", [Status]::NotRun)
            }

        }

    }
    catch {
        [Log]::OverwriteLine($Describe, [Status]::Fail)
        Write-Host ""
        throw $_
    }
}



function Invoke-ChecklistDscRequirement {
    Param(
        [string]$Describe,
        [string]$ResourceName,
        [string]$ModuleName,
        [hashtable]$Property
    )

    $dscParams = @{
        Name       = $ResourceName
        ModuleName = $ModuleName
        Property   = $Property
    }

    Invoke-ChecklistRequirement `
        -Describe $Describe `
        -Test {Invoke-DscResource -Method "Test" @dscParams} `
        -Set {Invoke-DscResource -Method "Set" @dscParams}

}