
$preCommitHook = @"
#!/bin/bash

pwsh ./test/Checkpoint-Output.ps1
git add ./test/integration
"@

$preCommitHookPath = "$PSScriptRoot/.git/hooks/pre-commit"

$preCommitHook > $preCommitHookPath
if (-not $IsWindows) {
    chmod u+x $preCommitHookPath
}
