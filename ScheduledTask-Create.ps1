Write-Output "Creating scheduled task for LibreWolf WinUpdater..."
$Title = "LibreWolf WinUpdater"
$Host.UI.RawUI.WindowTitle = $Title
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Output "Requesting administrator privileges"
  $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $UserName = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${User}`" `"${UserName}`""
  Exit
}

$Action   = New-ScheduledTaskAction -Execute "$PSScriptRoot\LibreWolf-WinUpdater.exe" -Argument "/Scheduled"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RunOnlyIfNetworkAvailable
$4Hours   = New-ScheduledTaskTrigger -Once -At (Get-Date -Minute 0 -Second 0).AddHours(1) -RepetitionInterval (New-TimeSpan -Hours 4)
$AtLogon  = New-ScheduledTaskTrigger -AtLogOn
$AtLogon.Delay = 'PT1M'
$User     = If ($Args[0]) {$Args[0]} Else {[System.Security.Principal.WindowsIdentity]::GetCurrent().Name}
$UserName = If ($Args[1]) {$Args[1]} Else {[Environment]::UserName}

Register-ScheduledTask -TaskName "$Title ($UserName)" -Action $Action -Settings $Settings -Trigger $4Hours,$AtLogon -User $User -RunLevel Highest -Force
Write-Output "Done. Press any key to close this window."
[Console]::ReadKey()