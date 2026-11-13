# Emit the module names of a process, for invocation by a 32-bit PowerShell.
# Usage: powershell.exe -File dump-modules32.ps1 -TargetPid 1234
# Kept as a file (not an inline -Command string) because inline escaping of $_ inside
# double-quoted -Command broke a previous attempt and produced 776 CategoryInfo errors
# instead of module names.
param([Parameter(Mandatory=$true)][int]$TargetPid)
$ErrorActionPreference = 'Stop'
$p = Get-Process -Id $TargetPid -ErrorAction Stop
$p.Modules | ForEach-Object { $_.ModuleName } | Sort-Object
