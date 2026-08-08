$Updater = "LibreWolf WinUpdater"
$Host.UI.RawUI.WindowTitle = "PowerShell: Remove $Updater scheduled task"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Output "`nTo remove the task, please allow PowerShell to make changes to your device.`n`nPress any key to continue..."
  [Console]::ReadKey()
  $UserName = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${UserName}`""
  Exit
}

$UserName = If ($Args[0]) {$Args[0]} Else {[Environment]::UserName}

Unregister-ScheduledTask -TaskName "$Updater ($UserName)" -Confirm:$False

If ($?) { Write-Output "`nTask removed." }
Write-Output "`nPress any key to continue..."
[Console]::ReadKey()