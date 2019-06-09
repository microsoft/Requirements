
class StreamLogger {
  
}


class LoggingContext {
  [string] $Tab = "  "
  [string] $Prefix = "BEGIN "
  [string] $Suffix = "END "
  [int] $Depth = 0
  [scriptblock] $Write = { Param($s) Write-Host $s }
  [void] invokeInContext([string] $label, [scriptblock] $scriptblock) {
    $start = Get-Date
    &$this.Write "$(Get-Date $start -Format hh:mm:ss)$($this.Tab * $this.Depth)$($this.Prefix)$label"
    $this.Depth++
    try {
      &$scriptblock
    }
    finally {
      $this.Depth--
    }
    $stop = Get-Date
    &$this.Write "$(Get-Date $stop -Format hh:mm:ss)$($this.Tab * $this.Depth)$($this.Suffix)$label"
  }
}
