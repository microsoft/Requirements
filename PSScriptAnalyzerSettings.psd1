@{
  'Rules' = @{
    'PSAvoidUsingCmdletAliases' = @{
      'Whitelist' = @(
        '?',
        '%',
        'foreach',
        'group',
        'measure',
        'select',
        'where'
      )
    }
  }
}