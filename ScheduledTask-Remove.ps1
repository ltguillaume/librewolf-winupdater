$Host.UI.RawUI.WindowTitle = "PowerShell: Remove LibreWolf WinUpdater scheduled task"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Output "`nTo remove the task, please allow PowerShell to make changes to your device.`n`nPress any key to continue..."
  [Console]::ReadKey()
  $UserName = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${UserName}`""
  Exit
}

$Title    = "LibreWolf WinUpdater"
$UserName = If ($Args[0]) {$Args[0]} Else {[Environment]::UserName}

Unregister-ScheduledTask -TaskName "$Title ($UserName)" -Confirm:$False
Write-Output "`nDone.`n`nPress any key to continue..."
[Console]::ReadKey()