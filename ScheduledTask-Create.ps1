$Updater = "LibreWolf WinUpdater"
$Host.UI.RawUI.WindowTitle = "PowerShell: Create $Updater scheduled task"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Output "`nTo create the task, please allow PowerShell to make changes to your device.`n`nPress any key to continue..."
  [Console]::ReadKey()
  $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $UserName = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${User}`" `"${UserName}`""
  Exit
}

$UserName = If ($Args[1]) {$Args[1]} Else {[Environment]::UserName}
$Action   = New-ScheduledTaskAction -Execute "LibreWolf-WinUpdater.exe" -Argument "/Scheduled" -WorkingDirectory "$PSScriptRoot"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DisallowHardTerminate -RunOnlyIfNetworkAvailable -StartWhenAvailable
$4Hours   = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 4)
$AtLogon  = New-ScheduledTaskTrigger -AtLogOn
$AtLogon.Delay = 'PT1M'
$User     = If ($Args[0]) {$Args[0]} Else {[System.Security.Principal.WindowsIdentity]::GetCurrent().Name}

Register-ScheduledTask -TaskName "$Updater ($UserName)" -Action $Action -Settings $Settings -Trigger $4Hours,$AtLogon -User $User -RunLevel Highest -Force
If ($?) { Write-Output "`nTask created." }
Write-Output "`nPress any key to continue..."
[Console]::ReadKey()