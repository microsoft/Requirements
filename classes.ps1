
using namespace System.Collections.Generic

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
#$VerbosePreference = "Continue"

Import-Module "Profile"



class Resource {
    [bool] Test() {
        throw "Abstract method"
        return $false
    }
    [void] Set() {
        throw "Abstract method"
    }
    [string] ToString() {
        throw "Abstract method"
        return ""
    }
    static [void] Run([resource[]]$resources) {
        foreach ($resource in $resources) {
            Write-Log $resource.Name {
                $pass = [bool](Write-Log "Test" {$resource.Test()})
                if (-not $pass) {
                    Write-Log "Set" {$resource.Set()}
                    $pass = [bool](Write-Log "Test" {$resource.Test()})
                    if (-not $pass) {
                        Write-Log "Failed"
                        throw "$($resource.Name) failed to install"
                    }
                }
            }
        }
    }
}





class Extension : Resource {

    static [string] $ConfigurationFileName = "Extensions.json"
    static [string] $Container = "C:\Extensions"
    static [PSCustomObject] $Configuration

    [ValidateNotNullOrEmpty()]
    [string] $Name
    [ValidateNotNullOrEmpty()]
    [string] $Path
    [ValidateNotNullOrEmpty()]
    [hashtable] $BaseParameters

    static Extension() {
        $fileName = [Extension]::ConfigurationFileName
        [Extension]::Configuration = Get-MergedConfig $fileName
    }

    Extension([string] $name) {
        $this.Name = $name
        $this.Path = [Extension]::Container + "\$name"
        $this.BaseParameters = @{
            Service       = $env:Service
            FlightingRing = $env:FlightingRing
            Region        = $env:Region
        }
        $this.BaseParameters[$this.Name] = [Extension]::Configuration.($this.Name)
    }

    [bool] Test() {
        $script = $this.Path + "\test.ps1"
        $params = $this.GetParameters($script)
        return &$script @params
    }

    [void] Set() {
        $script = $this.Path + "\set.ps1"
        $params = $this.GetParameters($script)
        &$script @params
    }

    [hashtable] GetParameters([string] $script) {
        $params = @{}
        $supportedParameters = (Get-Command $script).ScriptBlock.Ast.ParamBlock.Parameters.Name `
            | % {$_ -replace "\$"}
        $this.BaseParameters.Keys `
            | ? {$_ -in $supportedParameters} `
            | % {$params[$_] = $this.BaseParameters[$_]}
        return $params
    }

}

