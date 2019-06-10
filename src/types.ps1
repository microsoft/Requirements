
. "$PSScriptRoot\loggers\ChecklistLogger.ps1"
. "$PSScriptRoot\loggers\StreamLogger.ps1"

class LoggingContext {
  [string] $Tab = "  "
  [string] $Prefix = "BEGIN "
  [string] $Suffix = "END "
  [int] $Depth = 0
  [scriptblock] $Write = { Param($s) Write-Host $s }
}

class Requirement {
  [ValidateNotNullOrEmpty()]
  [string] $Name = (New-Guid)
  [ValidateNotNullOrEmpty()]
  [string] $Describe
  [scriptblock] $Test
  [scriptblock] $Set
  [string[]] $DependsOn
}

enum Method {
  Test
  Set
  Validate
}

enum LifecycleState {
  Start
  Stop
}

class RequirementEvent {
  [Requirement] $Requrement
  [datetime] $Date = (Get-Date)
  [Method] $Method
  [LifecycleState] $State
  $Result
}
