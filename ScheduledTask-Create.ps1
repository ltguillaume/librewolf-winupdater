If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}

$Action= New-ScheduledTaskAction -Execute "$PSScriptRoot\LibreWolf-WinUpdater.exe" -Argument "/Scheduled"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RunOnlyIfNetworkAvailable
$Trigger = @(
  $(New-ScheduledTaskTrigger -AtLogOn),
  $(New-ScheduledTaskTrigger -Once -At 0:00 -RepetitionInterval (New-TimeSpan -Hours 4))
)
$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Register-ScheduledTask -TaskName "LibreWolf WinUpdater" -Action $Action -Settings $Settings -Trigger $Trigger -User $User -RunLevel Highest –Force
Write-Output Done.

Pause