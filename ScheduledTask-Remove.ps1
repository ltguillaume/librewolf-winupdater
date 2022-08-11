If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process
  $User = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${User}`""
  Exit
}

$User = If ($Args[0]) {$Args[0]} Else {[Environment]::UserName}

Unregister-ScheduledTask -TaskName "LibreWolf WinUpdater ($User)" -Confirm:$False
Write-Output Done.
[Console]::ReadKey()