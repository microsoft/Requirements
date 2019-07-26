
$ErrorActionPreference = "Stop"
Import-Module "$PSScriptRoot\Requirements.psd1" -Force



$requirements = @(
    @{
        Name     = "Resource 1"
        Describe = "Resource 1 is present in the system"
        Test     = { $mySystem -contains 1 }
        Set      = { $mySystem.Add(1) | Out-Null; Start-Sleep 1 }
    },
    @{
        Name     = "Resource 2"
        Describe = "Resource 2 is present in the system"
        Test     = { $mySystem -contains 2 }
        Set      = { $mySystem.Add(2) | Out-Null; Start-Sleep 1 }
    },
    @{
        Name     = "Resource 3"
        Describe = "Resource 3 is present in the system"
        Test     = { $mySystem -contains 3 }
        Set      = { throw "This should not have been reached!"; Start-Sleep 1 }
    },
    @{
        Name     = "Resource 4"
        Describe = "Resource 4 is present in the system"
        Test     = { $mySystem -contains 4 }
        Set      = { throw "This should not have been reached!"; Start-Sleep 1 }
    },
    @{
        Name     = "Resource 5"
        Describe = "Resource 5 is present in the system"
        Test     = { $mySystem -contains 5 }
        Set      = { $mySystem.Add(5) | Out-Null; Start-Sleep 1 }
    }
)

# demo using Format-Table
$mySystem = [System.Collections.ArrayList]::new()
$mySystem.Add(3) | Out-Null
$mySystem.Add(4) | Out-Null
$requirements | Invoke-Requirement | Format-Table

# demo using Format-Checklist
$mySystem = [System.Collections.ArrayList]::new()
$mySystem.Add(3) | Out-Null
$mySystem.Add(4) | Out-Null
$requirements | Invoke-Requirement | Format-Checklist

# demo using Format-CallStack
$mySystem = [System.Collections.ArrayList]::new()
$mySystem.Add(3) | Out-Null
$mySystem.Add(4) | Out-Null
$requirements | Invoke-Requirement | Format-CallStack

# demo using Format-Callstack with nested requirements
$mySystem = [System.Collections.ArrayList]::new()
$complexRequirements = @(
    @{
        Name     = "Resource 1"
        Describe = "Resource 1 is present in the system"
        Test     = { $mySystem -contains 1 }
        Set      = { $mySystem.Add(1) | Out-Null; Start-Sleep 1 }
    },
    @{
        Name     = "Resource 2"
        Describe = "Resource 2 is present in the system"
        Test     = { $mySystem -contains 3 -and $mySystem -contains 4 }
        Set      = {
            @(
                @{
                    Name     = "Resource 3"
                    Describe = "Resource 3 is present in the system"
                    Test     = { $mySystem -contains 3 }
                    Set      = { $mySystem.Add(3) | Out-Null; Start-Sleep 1 }
                },
                @{
                    Name     = "Resource 4"
                    Describe = "Resource 4 is present in the system"
                    Test     = { $mySystem -contains 4 }
                    Set      = { $mySystem.Add(4) | Out-Null; Start-Sleep 1 }
                }
            ) | Invoke-Requirement
        }
    },
    @{
        Name     = "Resource 5"
        Describe = "Resource 5 is present in the system"
        Test     = { $mySystem -contains 5 }
        Set      = { $mySystem.Add(5) | Out-Null; Start-Sleep 1 }
    }
)
$complexRequirements | Invoke-Requirement | Format-CallStack
