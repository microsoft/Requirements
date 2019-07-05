# Requirements
Requirements is a PowerShell Gallery module for declaratively describing a system as a set of "requirements", then idempotently setting each requirement to its desired state.

The background motivation and implementation design are discussed in detail in [Declarative Idempotency](https://itnext.io/declarative-idempotency-aaa07c6dd9a0?source=friends_link&sk=f0464e8e29525b23aabe766bfb557dd7).

## Usage

We use the term `Test` to refer to the condition that describes whether the Requirement is in its desired state.  We use the term `Set` to refer to the command that a `Requirement` uses to put itself in its desired state if it is known to not be in its desired state.

### Declaring requirements
The easiest way to declare a requirement is to define it as a hashtable and let PowerShell's implicit casting handle the rest.

```powershell
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
        Set      = { $mySystem.Add(3) | Out-Null; Start-Sleep 1 }
    },
    @{
        Name     = "Resource 4"
        Describe = "Resource 4 is present in the system"
        Test     = { $mySystem -contains 4 }
        Set      = { $mySystem.Add(4) | Out-Null; Start-Sleep 1 }
    },
    @{
        Name     = "Resource 5"
        Describe = "Resource 5 is present in the system"
        Test     = { $mySystem -contains 5 }
        Set      = { $mySystem.Add(5) | Out-Null; Start-Sleep 1 }
    }
)
```

#### Validation Requirements
If you wish to assert that a precondition is met before continuing, you can leave out the `Set` block.  This is useful for [Defensive programming](https://itnext.io/defensive-powershell-with-validation-attributes-8e7303e179fd?source=friends_link&sk=14765ca9554709a77f8af7d73612ef5b), or when a Requirement requires manual steps.

```powershell
@{
    Name     = "Resource 1"
    Describe = "Azure CLI is authenticated"
    Test     = { az account }
}
```

#### Idempotent `Set` blocks
Sometimes, your `Set` block is already idempotent and an associated `Test` block cannot be defined.  In this case, you can leave out the `Test` block.

```powershell
@{
    Name     = "Resource 1"
    Describe = "Initial state of system is backed up"
    Set      = { Get-StateOfSystem | Out-File "$BackupContainer/$(Get-Date -Format 'yyyyMMddhhmmss').log" }
]
```

### Idempotently Setting requirements 
Simply pipe an array of `Requirement`s to `Invoke-Requirement`

```powershell
$requirements | Invoke-Requirement
```

### Formatting the logs
`Invoke-Requirement` will output logging events for each step in a `Requirement`'s execution lifecycle.  You can capture these logs with `Format-Table` or `Format-List`, or 

```powershell
$requirements | Invoke-Requirement | Format-Table
```

#### `Format-Table`
These logs were using `-Autosize` parameter, which better formats the columns, but does not support outputting as a stream.
```
  Method Lifecycle Name       Date
  ------ --------- ----       ----
    Test     Start Resource 1 6/12/2019 12:00:25 PM
    Test      Stop Resource 1 6/12/2019 12:00:25 PM
     Set     Start Resource 1 6/12/2019 12:00:25 PM
     Set      Stop Resource 1 6/12/2019 12:00:26 PM
Validate     Start Resource 1 6/12/2019 12:00:26 PM
Validate      Stop Resource 1 6/12/2019 12:00:26 PM
    Test     Start Resource 2 6/12/2019 12:00:26 PM
    Test      Stop Resource 2 6/12/2019 12:00:26 PM
     Set     Start Resource 2 6/12/2019 12:00:26 PM
...
```

#### `Format-Checklist`
`Format-Checklist` will present a live-updating checklist to the user.

![Format-Checklist output](https://raw.githubusercontent.com/microsoft/requirements/master/imgs/checklist.png)

#### `Format-Callstack`
Unlike `Format-Checklist`, `Format-Callstack` prints all log events and includes metadata.  For complex use cases, you can define nested `Requirement`s (`Requirement`s that contain more `Requirement`s in their `Set` block).  `Format-Callstack` will print the stack of `Requirement` names of each `Requirement` as its processed.

![Format-Callstack output](https://raw.githubusercontent.com/microsoft/requirements/master/imgs/callstack.png)

### Defining DSC Resources
If you're using Windows and PowerShell 5, you can use DSC resources with Requirements.

```PowerShell
$requirement = @{
    Describe     = "My Dsc Requirement"
    ResourceName = "File"
    ModuleName   = "PSDesiredStateConfiguration"
    Property     = @{
        Contents        = "Hello World"
        DestinationPath = "C:\myFile.txt"
        Force           = $true
    }
}
New-Requirement @requirement | Invoke-Requirement | Format-Checklist
```

## Comparison to DSC
Desired State Configurations allow you to declaratively describe a configuration then let the configuration manager handle with setting the configuration to its desired state.  This pattern from the outside may seem similar to Requirements, but there are crucial differences.

DSC is optimized for handling *many* configurations *asynchronously*.  For example, applying a configuration in parallel to multiple nodes.  In contrast, Requirements applies a *single* configuration *synchronously*.  This enables usage in different scenarios, including:
* CI/CD scripts
* CLIs
* Dockerfiles
* Linux

While Requirements supports DSC resources, it does not have a hard dependency on DSC's configuration manager, so if your Requirements do not include DSC resources they will work on any platform that PowerShell Core supports.

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
