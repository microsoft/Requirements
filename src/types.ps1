
class Requirement {
  [string] $Name
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
  [Requirement] $Requirement
  [datetime] $Date
  [Method] $Method
  [LifecycleState] $State
  [PSObject] $Result
}
