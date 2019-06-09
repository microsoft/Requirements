
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
