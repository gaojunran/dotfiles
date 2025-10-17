$bashConflicts = @('cat', 'cd', 'cp', 'diff', 'kill', 'ls', 'mv', 'ps', 'rm', 'sleep', 'sort', 'start', 'tee')

foreach ($alias in $bashConflicts) {
    if (Get-Alias -Name $alias -ErrorAction SilentlyContinue) {
        Remove-Item "Alias:\$alias" -Force -ErrorAction SilentlyContinue
    }
}
