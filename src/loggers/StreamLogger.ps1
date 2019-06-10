
class StreamLogger {

  hidden [int] $Depth = 0

  hidden [void] WriteLine([string] $message) {
    $tab = $this.Depth * ' '
    $timestamp = Get-Date -Format "hh:mm:ss" # TODO
    Write-Host "$tab$timestamp$message"
  }

  [void] BeginPrecheck() {
    $this.WriteLine($message)
  }

  [void] EndPrecheck([boolean] $inDesiredState) {
    $this.WriteLine($message)
  }

  [void] BeginSet() {
    $this.WriteLine($message)

  }

  [void] EndSet() {
    $this.WriteLine($message)
  }

  [void] BeginValidate() {
    $this.WriteLine($message)
  }

  [void] EndValidate([boolean] $validated) {
    $this.WriteLine($message)
  }

}