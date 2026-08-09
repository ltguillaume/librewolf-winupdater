$Browser = "LibreWolf"
$Hours   = 4

$Updater = "$Browser WinUpdater"
$Host.UI.RawUI.WindowTitle = "$Updater Task Scheduler"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Output "`nTo enable automatic updates, please allow PowerShell to make changes to your device.`n`nPress any key to continue..."
  [Console]::ReadKey()
  $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $UserName = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${User}`" `"${UserName}`""
  Exit
}

$UserName = If ($Args[1]) {$Args[1]} Else {[Environment]::UserName}
$TaskName = "$Updater ($UserName)"
$Action   = New-ScheduledTaskAction -Execute "$Browser-WinUpdater.exe" -Argument "/Scheduled" -WorkingDirectory "$PSScriptRoot"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DisallowHardTerminate -RunOnlyIfNetworkAvailable -StartWhenAvailable
$Interval = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $Hours)
$AtLogon  = New-ScheduledTaskTrigger -AtLogOn
$AtLogon.Delay = 'PT1M'
$User     = If ($Args[0]) {$Args[0]} Else {[System.Security.Principal.WindowsIdentity]::GetCurrent().Name}

Register-ScheduledTask -TaskName $TaskName -Action $Action -Settings $Settings -Trigger $Interval,$AtLogon -User $User -RunLevel Highest -Force
If ($?) { Write-Output "`nTask for automatic updates created successfully." }
Write-Output "`nPress any key to continue..."
[Console]::ReadKey()