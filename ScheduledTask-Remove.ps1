If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process
  $User = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -NoExit -File `"$PSCommandPath`" `"${User}`""
  Exit
}

Unregister-ScheduledTask -TaskName "LibreWolf WinUpdater ($Args)" -Confirm:$False
Write-Output Done.