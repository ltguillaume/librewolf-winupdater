$Browser = "LibreWolf"

$Updater = "$Browser WinUpdater"
$Host.UI.RawUI.WindowTitle = "$Updater Task Scheduler"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Output "`nTo disable automatic updates, please allow PowerShell to make changes to your device.`n`nPress any key to continue..."
  [Console]::ReadKey()
  $UserName = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${UserName}`""
  Exit
}

$UserName = If ($Args[0]) {$Args[0]} Else {[Environment]::UserName}
$TaskName = "$Updater ($UserName)"

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$False

If ($?) { Write-Output "`n$TaskName`n`nTask for automatic updates removed successfully." }
Write-Output "`nPress any key to continue..."
[Console]::ReadKey()