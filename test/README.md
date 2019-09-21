# Testing

## Unit testing
Pester tests are set up in this folder.  They are run in CI by `/.github/scripts/Assert-Tests.ps1`.

## Managing output of formatters
`/test/Checkpoint-Output.ps1` saves cases of formatter output to `/test/integration`.  These examples are checked into source control so they can be diffed in pull requests.

Run `/Initialize-Repo.ps1` to configure a pre-commit git hook to automatically run `/test/Checkpoint-Output.ps1` prior to committing changes.
