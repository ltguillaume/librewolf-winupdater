; LibreWolf WinUpdater - https://github.com/ltGuillaume/LibreWolf-WinUpdater
;@Ahk2Exe-SetFileVersion 1.2.5

;@Ahk2Exe-Bin Unicode 64*
;@Ahk2Exe-SetDescription LibreWolf WinUpdater
;@Ahk2Exe-SetMainIcon LibreWolf-WinUpdater.ico
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,160`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,206`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,207`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,208`, ,,,,1

ExeFile    := "librewolf.exe"
IniFile    := A_ScriptDir "\LibreWolf-WinUpdater.ini"
IsPortable := False
Verbose    := A_Args[1] <> "/Scheduled"

; Strings
_Title               = LibreWolf WinUpdater
_GetPathError        = Could not find the path to LibreWolf.`nBrowse to %ExeFile% in the following dialog.
_SelectFileTitle     = %_Title% - Select %ExeFile%...
_GetVersionError     = Could not determine current version of LibreWolf.
_DownloadJsonError   = Could not download releases file to check for a new version.
_FindUrlError        = Could not find the URL to download LibreWolf.
_Downloading         = Downloading update for LibreWolf...
_DownloadSetupError  = Could not download the LibreWolf setup file.
_FindSumsUrlError    = Could not find the URL to the checksum file.
_FindChecksumError   = Could not find the checksum for the downloaded file.
_ChecksumMatchError  = The file checksum did not match, so it's possible the download failed.
_NoChangesMade       = No changes were made.
_Extracting          = Extracting update for LibreWolf...
_Installing          = Installing update for LibreWolf...
_SilentUpdateError   = Silent update did not complete.`nDo you want to run the interactive installer?
_NewVersionFound     = A new version has been found.`nStart the update by closing LibreWolf.
_NoNewVersion        = No new LibreWolf version found.
_ExtractionError     = Could not extract archive of portable version.
_MoveToTargetError   = Could not move the extracted files into the target folder.
_IsUpdated           = LibreWolf has just been updated
_From                = from
_To                  = to

; Preparation
#NoEnv
EnvGet Temp, Temp
OnExit, Exit
FileGetVersion, UpdaterVersion, %A_ScriptFullPath%
UpdaterVersion := SubStr(UpdaterVersion, 1, -2)
Menu, Tray, Tip, %_Title% %UpdaterVersion%
If !A_IsCompiled
	Menu, Tray, Icon, %A_ScriptDir%\LibreWolf-WinUpdater.ico

; Change notifications somewhat if run from portable version
Process, Exist, LibreWolf-Portable.exe
If ErrorLevel
	RunningPortable := True
; If there's a version number, assume it's my portable version and don't overwrite later on
Else
	FileGetVersion, MyPortableVersion, %A_ScriptDir%\LibreWolf-Portable.exe

; Get the path to LibreWolf
If FileExist(A_ScriptDir "\LibreWolf-Portable.exe") {
; Portable LibreWolf is present
	IsPortable := True
	Path := A_ScriptDir "\LibreWolf\librewolf.exe"
} Else {
	IniRead, Path, %IniFile%, Settings, Path, 0
	If !Path
		RegRead, Path, HKLM\SOFTWARE\Clients\StartMenuInternet\LibreWolf\shell\open\command
	If Errorlevel
		Path = %A_ProgramFiles%\LibreWolf\%ExeFile%
}

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
RegExMatch(ReleaseInfo, "i)Release v(.+?)""", Release)
StrReplace(Release1, ".",, DotCount)
If DotCount < 2
	Release1 := Release1 ".0"
;MsgBox, ReleaseInfo = %ReleaseInfo%`nCurrentVersion = %CurrentVersion%`nRelease1 = %Release1%
If (Release1 = CurrentVersion) {
	If Verbose {
		TrayTip,, %_NoNewVersion%,, 16
		Sleep, 6000
	}
	IniWrite, %_NoNewVersion%, %IniFile%, Log, LastResult
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
Download  := File.Read(4096)
FilenameEnd := IsPortable ? "win64.zip" : "setup.exe"
RegExMatch(Download, "i)" FilenameEnd """,""url"":""(\Qhttps://gitlab.com/librewolf-community/browser/windows/uploads/\E.+?\/(librewolf-.+?" FilenameEnd "))", DownloadUrl)
;MsgBox, Downloading`n%DownloadUrl1%`nto`n%DownloadUrl2%
If !DownloadUrl1 Or !DownloadUrl2
	Die(_FindUrlError)

; Download setup file
If Verbose
	TrayTip, %_Downloading%, v%Release1%,, 16
SetupFile := DownloadUrl2
UrlDownloadToFile, %DownloadUrl1%, %SetupFile%
If !FileExist(SetupFile)
	Die(_DownloadSetupError)

; Get checksum file
ChecksumFile = LibreWolf-Checksum.txt
RegExMatch(Download, "i)sha256sums.txt"",""url"":""(\Qhttps://gitlab.com/librewolf-community/browser/windows/uploads/\E.+?/sha256sums\.txt)", ChecksumUrl)
If !ChecksumUrl1
	Die(_FindSumsUrlError)
UrlDownloadToFile, %ChecksumUrl1%, %ChecksumFile%

; Get checksum for downloaded file
File.Close()
File := FileOpen(ChecksumFile, "r")
While !File.AtEOF {
	ChecksumLine := File.ReadLine()
	RegExMatch(ChecksumLine, "i)(.+?)\s+\Q" SetupFile "\E", Checksum)
	If Checksum1
		Break
}
If !Checksum1
	Die(_FindChecksumError)

; Compare checksum with downloaded file
RunWait, powershell -NoProfile -Command "Exit (Get-FileHash """%SetupFile%""").Hash -eq """%Checksum1%"""",, Hide
If !ErrorLevel
	Die(_ChecksumMatchError)

; Extract archive of portable version
If IsPortable {
	If Verbose
		TrayTip, %_Extracting%, v%Release1%,, 16
	FileRemoveDir, LibreWolf-Extracted, 1
	RunWait, powershell.exe -NoProfile -Command "Expand-Archive """%SetupFile%""" LibreWolf-Extracted" -ErrorAction Stop,, Hide
	If ErrorLevel
		Die(_ExtractionError)
	Loop, Files, LibreWolf-Extracted\*, D
	{
		FileMoveDir, %A_LoopFilePath%, %A_ScriptDir%, 2
		If Errorlevel
			Die(_MoveToTargetError)
	}
	Goto, Report
}

; Or run silent setup
If Verbose
	TrayTip, %_Installing%, v%Release1%,, 16
Folder := StrReplace(Path, ExeFile)
;MsgBox, %SetupFile% /S /D=%Folder%
RunWait, %SetupFile% /S /D=%Folder%,, UseErrorLevel
If ErrorLevel {
	MsgBox, 52, %_Title%, %_SilentUpdateError%
	IfMsgBox Yes
		RunWait, %SetupFile% /D=%Folder%,, UseErrorLevel
}

; Report update if completed
Report:
FileGetVersion, NewVersion, %Path%
StringLeft, NewVersion, NewVersion, InStr(NewVersion, ".",, -1) - 1
If NewVersion = %CurrentVersion%
	Exit
FormatTime, CurrentTime
IniWrite, %CurrentTime%, %IniFile%, Log, LastUpdate
IniWrite, %CurrentVersion%, %IniFile%, Log, LastUpdateFrom
IniWrite, %NewVersion%, %IniFile%, Log, LastUpdateTo
IniWrite, %_IsUpdated% %_From% v%CurrentVersion% %_To% v%NewVersion%., %IniFile%, Log, LastResult
TrayTip, %_IsUpdated%, %_From% v%CurrentVersion% %_To% v%NewVersion%,, 16
Sleep, 60000
Exit

; Clean up
Exit:
File.Close()
FormatTime, CurrentTime
IniWrite, %CurrentTime%, %IniFile%, Log, LastRun
Sleep, 2000
If ReleaseFile
	FileDelete, %ReleaseFile%
If SetupFile
	FileDelete, %SetupFile%
If ChecksumFile
	FileDelete, %ChecksumFile%
If IsPortable
	FileRemoveDir, LibreWolf-Extracted, 1

Die(Error) {
	Global Verbose, _Title, _NoChangesMade
	IniWrite, %Error%, %IniFile%, Log, LastResult
	If Verbose
		MsgBox, 48, %_Title%, %Error%`n%_NoChangesMade%
	Exit
}