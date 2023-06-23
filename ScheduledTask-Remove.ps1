Write-Output "Removing scheduled task for LibreWolf WinUpdater..."
$Title = "LibreWolf WinUpdater"
$Host.UI.RawUI.WindowTitle = $Title
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Output "Requesting administrator privileges"
  $User = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${User}`""
  Exit
}

$User = If ($Args[0]) {$Args[0]} Else {[Environment]::UserName}

Unregister-ScheduledTask -TaskName "$Title ($User)" -Confirm:$False
Write-Output "Done. Press any key to close this window."
[Console]::ReadKey()