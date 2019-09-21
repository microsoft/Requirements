
$preCommitHook = @"#/bin/bash

pwsh ./test/Checkpoint-Output.ps1
git add ./test/integration
"@

$preCommitHookPath = "$PSScriptRoot/.git/hooks/pre-commit"

$preCommitHook > $preCommitHookPath
chmod u+x $preCommitHookPath
