; LibreWolf WinUpdater - https://github.com/ltGuillaume/LibreWolf-WinUpdater
;@Ahk2Exe-SetFileVersion 1.0.0

;@Ahk2Exe-Bin Unicode 64*
;@Ahk2Exe-SetDescription LibreWolf WinUpdater
;@Ahk2Exe-SetMainIcon LibreWolf-WinUpdater.ico
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,160`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,206`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,207`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,208`, ,,,,1

Global ExeFile = "librewolf.exe"
Global IniFile = A_ScriptDir "\LibreWolf-WinUpdater.ini"

; Strings
_Title               = LibreWolf WinUpdater
_GetPathError        = Could not find the path to LibreWolf.`nBrowse to %ExeFile% in the following dialog.
_SelectFileTitle     = %_Title% - Select %ExeFile%...
_GetVersionError     = Could not determine current version of LibreWolf.
_DownloadJsonError   = Could not download releases file to check for a new version.
_FindUrlError        = Could not find the URL to download LibreWolf.
_DownloadSetupError  = Could not download the LibreWolf setup file.
_SilentUpdateError   = Silent update did not complete.`nDo you want to run the interactive installer?
_NewVersionFound     = A new version has been found.`nStart the update by closing LibreWolf.
_NoNewVersion        = No new version found
_IsUpdated           = LibreWolf has just been updated from
_To                  = to

; Preparation
#NoEnv
EnvGet Temp, Temp
FileGetVersion, UpdaterVersion, %A_ScriptFullPath%
UpdaterVersion := SubStr(UpdaterVersion, 1, -2)
OnExit, Exit
Menu, Tray, Tip, %_Title% %UpdaterVersion%
If !A_IsCompiled
	Menu, Tray, Icon, %A_ScriptDir%\LibreWolf-WinUpdater.ico

; Get the path to LibreWolf
IniRead, Path, %IniFile%, Settings, Path, %ProgramFiles%\LibreWolf\%ExeFile%
CheckPath:
If !FileExist(Path) {
	MsgBox, 48, %_Title%, %_GetPathError%
	FileSelectFile, Path, 3, %Path%, %_SelectFileTitle%, %ExeFile%
	If ErrorLevel
		Exit
	Else {
		IniWrite, %Path%, %IniFile%, Settings, Path
		Goto, CheckPath
	}
}

; Get the current version
FileGetVersion, CurrentVersion, %Path%
StringLeft, CurrentVersion, CurrentVersion, InStr(CurrentVersion, ".",, -1) - 1
If ErrorLevel
	Die(_GetVersionError)

; Download release info
DownloadInfo:
SetWorkingDir, %Temp%
ReleaseFile = LibreWolf-Release.json
UrlDownloadToFile, https://gitlab.com/api/v4/projects/13852981/releases, %ReleaseFile%
File := FileOpen(ReleaseFile, "r")
If !File
	Die(_DownloadJsonError)

; Compare versions
ReleaseInfo := File.Read(64)
;MsgBox, Release = %ReleaseInfo% | Version = %Version%
If InStr(ReleaseInfo, CurrentVersion) {
	IniWrite, %_NoNewVersion%, %IniFile%, Data, LastResult
	Exit
}

; Notify and wait if LibreWolf is running
Process, Exist, %ExeFile%
If ErrorLevel {
	TrayTip,, %_NewVersionFound%,, 16
	Process, WaitClose, %ExeFile%
	Goto, DownloadInfo
}

; Get setup file URL
Download := File.Read(4096)
SetupFile = LibreWolf-Update.exe
RegExMatch(Download, "i)https://gitlab.com/librewolf-community/browser/windows/uploads/.*?\.exe", DownloadUrl)
;MsgBox, Downloading`n%DownloadUrl%`nto`n%SetupFile%
If !DownloadUrl
	Die(_FindUrlError)

; Download setup file
UrlDownloadToFile, %DownloadUrl%, %SetupFile%
If !FileExist(SetupFile)
	Die(_DownloadSetupError)

; Run setup
RunWait, %SetupFile% /S,, UseErrorLevel
If ErrorLevel {
	MsgBox, 52, %_Title%, %_SilentUpdateError%
	IfMsgBox Yes
		RunWait, %SetupFile%,, UseErrorLevel
}

; Report update if completed
FileGetVersion, NewVersion, %Path%
StringLeft, NewVersion, NewVersion, InStr(NewVersion, ".",, -1) - 1
If NewVersion = %CurrentVersion%
	Exit
IniWrite, %CurrentVersion%, %IniFile%, Data, LastUpdateFrom
IniWrite, %NewVersion%, %IniFile%, Data, LastUpdateTo
IniWrite, %_IsUpdated% v%CurrentVersion% %_To% v%NewVersion%, %IniFile%, Data, LastResult
TrayTip,, %_IsUpdated%`nv%CurrentVersion% %_To%`nv%NewVersion%,, 16
Sleep, 10000

; Clean up
Exit:
FormatTime, CurrentTime
IniWrite, %CurrentTime%, %IniFile%, Data, LastRun
If ReleaseFile
	FileDelete, %ReleaseFile%
If SetupFile
	FileDelete, %SetupFile%

Die(Error) {
	IniWrite, %Error%, %IniFile%, Data, LastResult
	If (A_Args[1] <> "/Scheduled")
		MsgBox, 48, %_Title%, %Error%
	Exit
}