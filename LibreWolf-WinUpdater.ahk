; LibreWolf WinUpdater - https://codeberg.org/ltguillaume/librewolf-winupdater
;@Ahk2Exe-SetFileVersion 1.7.1

;@Ahk2Exe-Base Unicode 32*
;@Ahk2Exe-SetCompanyName LibreWolf Community
;@Ahk2Exe-SetDescription LibreWolf WinUpdater
;@Ahk2Exe-SetMainIcon LibreWolf-WinUpdater.ico
;@Ahk2Exe-AddResource LibreWolf-WinUpdaterBlue.ico, 160
;@Ahk2Exe-SetOrigFilename LibreWolf-WinUpdater.exe
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,206`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,207`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,208`, ,,,,1

#NoEnv
#SingleInstance, Off

Global Args       := ""
, IniFile         := A_ScriptDir "\LibreWolf-WinUpdater.ini"
, TaskCreateFile  := "ScheduledTask-Create.ps1"
, TaskRemoveFile  := "ScheduledTask-Remove.ps1"
, LibreWolfExe    := "librewolf.exe"
, PortableExe     := A_ScriptDir "\LibreWolf-Portable.exe"
, SelfUpdateZip   := "LibreWolf-WinUpdater.zip"
, ExtractDir      := A_Temp "\LibreWolf-Extracted"
, IsPortable      := FileExist(A_ScriptDir "\LibreWolf-Portable.exe")
, RunningPortable := A_Args[1] = "/Portable"
, Scheduled       := A_Args[1] = "/Scheduled"
, SettingTask     := A_Args[1] = "/CreateTask" Or A_Args[1] = "/RemoveTask"
, ChangesMade     := False
, Path, ProgramW6432, Build, UpdateSelf, Task, CurrentUpdaterVersion, ReleaseInfo, CurrentVersion, NewVersion, SetupFile, GuiHwnd, LogField, Progress, VerField, TaskSetField, UpdateButton

; Strings
Global _LibreWolf     := "LibreWolf"
, _Updater            := "LibreWolf WinUpdater"
, _NoConnection       := "Could not establish a connection to GitLab."
, _IsRunningError     := _Updater " is already running."
, _IsElevated         := "To set up scheduled tasks properly, please do not run WinUpdater as administrator."
, _NoDefaultBrowser   := "Could not open your default browser."
, _Checking           := "Checking for new version..."
, _TaskSet            := "Schedule a task for automatic update checks while user {} is logged on."
, _GetPathError       := "Could not find the path to LibreWolf.`nBrowse to " LibreWolfExe " in the following dialog."
, _SelectFileTitle    := _Updater " - Select " LibreWolfExe "..."
, _WritePermError     := "Could not write to`n{}. Please check the current user account's write permissions for this folder."
, _CopyError          := "Could not copy {}"
, _GetBuildError      := "Could not determine the build architecture (32/64-bit) of LibreWolf."
, _GetVersionError    := "Could not determine the current version of`n{}"
, _DownloadJsonError  := "Could not download the {Task} releases file."
, _JsonVersionError   := "Could not get version info from the {Task} releases file."
, _FindUrlError       := "Could not find the URL to download {Task}."
, _Downloading        := "Downloading new version..."
, _DownloadSelfError  := "Could not download the new WinUpdater version."
, _DownloadSetupError := "Could not download the setup file."
, _Downloaded         := "New version downloaded."
, _FindSumsUrlError   := "Could not find the URL to the checksum file."
, _FindChecksumError  := "Could not find the checksum for the downloaded file."
, _ChecksumMatchError := "The file checksum did not match, so it's possible the download failed."
, _ChangesMade        := "However, new files were written to the target folder!"
, _NoChangesMade      := "No changes were made to your LibreWolf folder."
, _Extracting         := "Extracting portable version..."
, _StartUpdate        := "  &Start update  "
, _Installing         := "Installing new version..."
, _UpdateError        := "Error while updating."
, _SilentUpdateError  := "Silent update did not complete.`nDo you want to run the interactive installer?"
, _NewVersionFound    := "A new version is available.`nClose LibreWolf to start updating..."
, _NoNewVersion       := "No new version found."
, _ExtractionError    := "Could not extract the {Task} archive.`nMake sure LibreWolf is not running and restart the updater."
, _MoveToTargetError  := "Could not move the following file into the target folder:`n{}"
, _IsUpdated          := "LibreWolf has been updated."
, _To                 := "to"
, _GoToWebsite        := "Please check the <a>project website</a> for possible solutions or open an issue to get help."

Init()
CheckPaths()
CheckArgs()
GetCurrentVersion()
If (ThisUpdaterRunning())
	Die(_IsRunningError,, False)	; Don't show this if Scheduled
Unelevate(A_ScriptFullPath, Args, A_ScriptDir)
CheckWriteAccess()
If (SettingTask)
	TaskSet()
CheckConnection()
If (UpdateSelf And A_IsCompiled)
	SelfUpdate()
If (GetNewVersion())
	StartUpdate()
Exit()

Init() {
	EnvGet, ProgramW6432, ProgramW6432
	IniRead, UpdateSelf, %IniFile%, Settings, UpdateSelf, 1	; Using "False" in .ini causes If (UpdateSelf) to be True
	FileGetVersion, CurrentUpdaterVersion, %A_ScriptFullPath%
	CurrentUpdaterVersion := SubStr(CurrentUpdaterVersion, 1, -2)
	SetWorkingDir, %A_Temp%
	Menu, Tray, Tip, %_Updater% %CurrentUpdaterVersion%
	Menu, Tray, NoStandard
	Menu, Tray, Add, Portable, About
	Menu, Tray, Add, WinUpdater, About
	Menu, Tray, Add, Exit, Exit
	Menu, Tray, Default, WinUpdater

	; Set up GUI
	Gui, New, +HwndGuiHwnd -MaximizeBox, %_Updater% %CurrentUpdaterVersion%
	Gui, Color, 23222B
	Gui, Add, Picture, x10 y10 w64 h64 Icon2, %A_ScriptFullPath%
	Gui, Font, c00ACFF s22 w700, Segoe UI
	Gui, Add, Text, x85 y4 BackgroundTrans, LibreWolf
	Gui, Font, cFFFFFF s9 w700
	Gui, Add, Text, vVerField x86 y42 w222 BackgroundTrans
	Gui, Font, w400
	Gui, Add, Progress, vProgress w217 h20 c00ACFF, 25
	Gui, Add, Text, vLogField w222 BackgroundTrans
	Gui, Margin,, 15

	If (SettingTask Or !A_Args.Length()) {	; No arguments: when not running as portable or as a scheduled task
		If (!IsPortable) {	; No scheduled tasks for portable version
			Gui, Add, CheckBox, vTaskSetField gTaskSet x15 y+10 w290 cBCBCBC Center Check3 -Tabstop, % StrReplace(_TaskSet, "{}", A_UserName)
			TaskCheck()
		}
		Gui, Show
	}
}

About(ItemName, GuiEvent) {
	Url := "https://codeberg.org/ltguillaume/librewolf-" (GuiEvent ? "WinUpdater" : ItemName)
	Try Run, %Url%
	Catch {
		RegRead, DefBrowser, HKCR, .html
		RegRead, DefBrowser, HKCR, %DefBrowser%\Shell\Open\Command
		Run, % StrReplace(DefBrowser, "%1", Url)
		If (ErrorLevel)
			MsgBox, 48, %_Updater%, %_NoDefaultBrowser%
	}
}

CheckPaths() {
	If (IsPortable)
		Path := A_ScriptDir "\LibreWolf\librewolf.exe"
	Else {
		IniRead, Path, %IniFile%, Settings, Path, 0	; Need to use 0, because False would become a string
		If (!Path)
			RegRead, Path, HKLM\SOFTWARE\Clients\StartMenuInternet\LibreWolf\shell\open\command
		If (ErrorLevel)
			Path = %ProgramW6432%\LibreWolf\%LibreWolfExe%

		Path := Trim(Path, """")	; FileExist chokes on double quotes
		If (!FileExist(Path))
			Path = %A_ProgramFiles%\LibreWolf\%LibreWolfExe%
	}
;MsgBox, Path = %Path%

	CheckPath:
	If (!FileExist(Path)) {
		MsgBox, 48, %_Updater%, %_GetPathError%
		FileSelectFile, Path, 3, %Path%, %_SelectFileTitle%, %LibreWolfExe%
		If (ErrorLevel)
			Exit()
		Else {
			IniWrite, %Path%, %IniFile%, Settings, Path
			Goto, CheckPath
		}
	}
}

CheckArgs() {
	Args := ""
	For i, Arg in A_Args
	{
		If (InStr(Arg, A_Space))
			Arg := """" Arg """"
		Args .= " " Arg
	}
}

ThisUpdaterRunning() {
	Process, Exist	; Put launcher's process id into ErrorLevel
	Query := "Select ProcessId from Win32_Process where ProcessId!=" ErrorLevel " and ExecutablePath=""" StrReplace(A_ScriptFullPath, "\", "\\") """"
	For Process in ComObjGet("winmgmts:").ExecQuery(Query)
		Return True
}

SelfUpdate() {
	Task := _Updater
;MsgBox, % GetLatestVersion() " = " CurrentUpdaterVersion
	If (GetLatestVersion() = CurrentUpdaterVersion)
		Return

	RegExMatch(ReleaseInfo, "i)name"":""librewolf-winupdater.+?\.zip"".*?browser_download_url"":""(.*?)""", DownloadUrl)
	If (!DownloadUrl1)
		Return Log("SelfUpdate", _FindUrlError, True)

	UrlDownloadToFile, %DownloadUrl1%, %SelfUpdateZip%
	If (!FileExist(SelfUpdateZip))
		Return Log("SelfUpdate", _DownloadSelfError, True)
;MsgBox, Extracting Self-Update
	FileMove, %A_ScriptFullPath%, %A_ScriptFullPath%.pbak, 1
	If (!Extract(A_Temp "\" SelfUpdateZip, A_ScriptDir))
		Return Log("SelfUpdate", _ExtractionError, True)

	If (IsPortable)
		FileDelete, %A_ScriptDir%\ScheduledTask*.ps1

	If (!FileExist(A_ScriptFullPath))
		Die(_ExtractionError)

	Run, %A_ScriptFullPath% %Args%
	ExitApp
}

CheckWriteAccess() {
	FileAppend,, %IniFile%
	If (!ErrorLevel)
		Return

	If (IsPortable)
		Die(_WritePermError, A_ScriptDir)

	AppData := A_AppData "\LibreWolf\WinUpdater"
	FileCreateDir, %AppData%
	If (ErrorLevel)
		Die(_WritePermError, A_ScriptDir)

	Files := [ A_ScriptName, TaskCreateFile, TaskRemoveFile ]
	For Index, File in Files {
		If (!FileExist(AppData "\" File))
			FileCopy, %A_ScriptDir%\%File%, %AppData%
		If (ErrorLevel)
			Die(_CopyError, File " " _To "`n" AppData)
	}

	Run, %AppData%\%A_ScriptName% %Args%
	ExitApp
}

GetCurrentVersion() {
	; by SKAN and Drugwash https://www.autohotkey.com/board/topic/70777-how-to-get-autohotkeyexe-build-information-from-file/?p=448263
	Call := DllCall("GetBinaryTypeW", "Str", "\\?\" Path, "UInt *", Build)
	If (Call And Build = 6)
		Build := "x86_64"
	Else If (Call And Build = 0)
		Build := "i686"
	Else
		Die(_GetBuildError)

	; FileVersion() by SKAN https://www.autohotkey.com/boards/viewtopic.php?&t=4282
	If (Sz := DllCall("Version\GetFileVersionInfoSizeW", "WStr", Path, "Int", 0))
		If (DllCall("Version\GetFileVersionInfoW", "WStr", Path, "Int", 0, "UInt", VarSetCapacity(V, Sz), "Str", V))
			If (DllCall("Version\VerQueryValueW", "Str", V, "WStr", "\StringFileInfo\000004B0\ProductVersion", "PtrP", pInfo, "Int", 0))
				CurrentVersion := StrGet(pInfo, "UTF-16")

	If (!CurrentVersion)
		Die(_GetVersionError, Path)

	GuiControl,, VerField, %CurrentVersion% (%Build%)
}

CheckConnection() {
	If (!Download("https://gitlab.com/manifest.json"))
		Die(_NoConnection,, False)	; Don't show this if not Scheduled
}

GetNewVersion() {
	Progress(_Checking)
	Task := _LibreWolf
	NewVersion := GetLatestVersion()
;MsgBox, ReleaseInfo = %ReleaseInfo%`nCurrentVersion = %CurrentVersion%`nNewVersion = %NewVersion%
	IniRead, LastUpdateTo, %IniFile%, Log, LastUpdateTo, False
	If (NewVersion = CurrentVersion) {
		Progress(_NoNewVersion, True)
		Log("LastResult", _NoNewVersion)
		Return False
	}
	Return True
}

StartUpdate() {
	GuiControl,, VerField, %CurrentVersion% %_To% %NewVersion% (%Build%)
	If (Portable Or !Scheduled)
		Gui, Show

	WaitForClose()
}

WaitForClose() {
	; Notify and wait if LibreWolf is running
	PathDS   := StrReplace(Path, "\", "\\")
	Notified := False
	For Proc in ComObjGet("winmgmts:").ExecQuery("Select ProcessId from Win32_Process where ExecutablePath=""" PathDS """") {
		If (!Notified) {
			Notify(_NewVersionFound)
			Notified := True
		}
		Process, WaitClose, % Proc.ProcessId
	}

	; Check for newer version since notification was shown
	If (GetNewVersion() And Notified)
		WaitForClose()

	DownloadUpdate()
}

DownloadUpdate() {
	; Get setup file URL
	FilenameEnd := Build (IsPortable ? "-portable\.zip" : "-setup\.exe")
	RegExMatch(ReleaseInfo, "i)""name"":""(librewolf-.{1,30}?" FilenameEnd ")"",\s*""url"":""(.+?)""", DownloadUrl)
;MsgBox, Downloading`n%DownloadUrl2%`nto`n%DownloadUrl1%
	If (!DownloadUrl1 Or !DownloadUrl2)
		Die(_FindUrlError)

	; Download setup file
	Progress(_Downloading)
	SetupFile := DownloadUrl1
	UrlDownloadToFile, %DownloadUrl2%, %SetupFile%
	If (!FileExist(SetupFile))
		Die(_DownloadSetupError)

	VerifyChecksum()
}

VerifyChecksum() {
	; Get checksum file
	RegExMatch(ReleaseInfo, "i)""name"":""sha256sums\.txt"",\s*""url"":""(.+?)""", ChecksumUrl)
	If (!ChecksumUrl1)
		Die(_FindSumsUrlError)
	Checksum := Download(ChecksumUrl1)

	; Get checksum for downloaded file
	RegExMatch(Checksum, "i)(\S+?)\s+\*?\Q" SetupFile "\E", Checksum)
	If (!Checksum1)
		Die(_FindChecksumError)

	; Compare checksum with downloaded file
	If (Checksum1 <> Hash(SetupFile))
		Die(_ChecksumMatchError)

	If (IsPortable)
		ExtractPortable()
	Else {
		If (A_IsAdmin)
			Install()
		Else {
			Progress(_Downloaded)
			Gui, Add, Button, vUpdateButton gInstall w148 x86 y110 Default, %_StartUpdate%
			GuiControl, Move, TaskSetField, y146
			ShowGui()
		}
	}
}

ExtractPortable() {
; Extract archive of portable version
	Progress(_Extracting)
	If (!Extract(A_Temp "\" SetupFile, ExtractDir))
		Die(_ExtractionError)

	Loop, Files, %ExtractDir%\*, D
	{
;MsgBox, Traversing %A_LoopFilePath%
		If (FileExist(A_LoopFilePath "\LibreWolf-WinUpdater.exe"))
			FileMove, %A_ScriptFullPath%, %A_ScriptFullPath%.pbak, 1
		SetWorkingDir, %A_LoopFilePath%	; Enter the first folder of the extracted archive
		Loop, Files, *, R
		{
			FileGetSize, CurrentFileSize, %A_ScriptDir%\%A_LoopFilePath%
;MsgBox, % A_LoopFilePath "`n" A_LoopFileSize "`n" CurrentFileSize "`n" Hash(A_LoopFilePath) "`n" Hash(A_ScriptDir "\" A_LoopFilePath)
			If (!FileExist(A_ScriptDir "\" A_LoopFileDir))
				FileCreateDir, %A_ScriptDir%\%A_LoopFileDir%
			If (!FileExist(A_ScriptDir "\" A_LoopFilePath) Or A_LoopFileSize <> CurrentFileSize Or Hash(A_LoopFilePath) <> Hash(A_ScriptDir "\" A_LoopFilePath)) {
;MsgBox, Moving %A_LoopFilePath%
				FileMove, %A_LoopFilePath%, %A_ScriptDir%\%A_LoopFilePath%, 1
				If (ErrorLevel)
					Die(_MoveToTargetError, A_LoopFilePath)
				ChangesMade := True
			}
		}
	}
	SetWorkingDir, %A_Temp%

	WriteReport()
}

Install() {
	Progress(_Installing)
	If (Scheduled)
		Notify(_Installing, CurrentVersion " " _To " v" NewVersion, 3000)
	Folder := StrReplace(Path, LibreWolfExe, "")
;MsgBox, %SetupFile% /S /D=%Folder%
	; Run silent setup
	RunWait, %SetupFile% /S /D=%Folder%,, UseErrorLevel
	If (!ErrorLevel)
		WriteReport()
	Else {
		MsgBox, 52, %_Updater%, %_SilentUpdateError%
		IfMsgBox No
			Progress(_UpdateError, True)
		Else {
			RunWait, %SetupFile% /D=%Folder%,, UseErrorLevel
			If (ErrorLevel)
				Progress(_UpdateError, True)
			Else
				WriteReport()
		}
	}
}

WriteReport() {
	; Report update if completed
	Log("LastUpdate", "(" Build ")", True)
	Log("LastUpdateFrom", CurrentVersion)
	Log("LastUpdateTo", NewVersion)
	Log("LastResult", _IsUpdated)
	Progress(_IsUpdated, True)
	Notify(_IsUpdated, CurrentVersion " " _To " v" NewVersion, Scheduled ? 60000 : 0)

	Exit()
}

Exit() {
; Wait for close
	If (!A_Args.Length() And WinExist("ahk_id " GuiHwnd))
		WinWaitClose, ahk_id %GuiHwnd%
	Else
		Gui, Destroy

; Clean up
	If (RunningPortable And FileExist(PortableExe)) {
		A_Args.RemoveAt(1)	; Remove "/Portable" from array
		CheckArgs()
;MsgBox, %Args%
		Run, %PortableExe% %Args%
	}
	Log("LastRun",, True)
	If (SetupFile) {
		Sleep, 2000
		FileDelete, %SetupFile%
	}
	If (IsPortable)
		FileRemoveDir, LibreWolf-Extracted, 1
	FileDelete, %A_ScriptFullPath%.pbak
	FileDelete, %SelfUpdateZip%
	ExitApp
}

; Helper functions

Die(Error, Var = False, Show = True) {
	If (Var)
		Error := StrReplace(Error, "{}", Var)
	Error := StrReplace(Error, "{Task}", Task)
	IniWrite, %Error%, %IniFile%, Log, LastResult
	GuiControl, Hide, Progress
	GuiControl, Hide, LogField
	GuiControl, Disable, TaskSetField
	GuiControl, Hide, TaskSetField
	Gui, Font, s36
	Gui, Add, Text, x256 y0 cYellow, % Chr("0x26A0")
	Gui, Font, s9
	Msg := Error " " (ChangesMade ? _ChangesMade : _NoChangesMade) "`n`n" _GoToWebsite
	Gui, Add, Link, gAbout x15 y81 w290 cCCCCCC, %Msg%
	ControlFocus, VerField
	ShowGui()
}

Download(URL) {
	Try {
		Object := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Object.Open("GET", URL)
		Object.Send()
		Result := Object.ResponseText
;MsgBox, %Result%
		Return Result
	} Catch {
		Return False
	}
}

Extract(From, To) {
;MsgBox, %From% to %To%
	FileRemoveDir, %ExtractDir%, 1
	FileCopyDir, %From%, %To%, 1
	Error := ErrorLevel
	If (Error) {	; PowerShell fallback
;MsgBox, Trying PowerShell fallback
		FileRemoveDir, %ExtractDir%, 1
		FileCreateDir, %ExtractDir%
		SetWorkingDir, %To%
		RunWait, powershell.exe -NoProfile -Command "Expand-Archive """%From%""" . -Force" -ErrorAction Stop,, Hide
		Error := ErrorLevel
		SetWorkingDir, %A_Temp%
	}
;MsgBox, Extract(%From%, %To%) ErrorLevel = %Error%

	Return !(Error <> 0)
}

GetLatestVersion() {
	ReleaseUrl := (Task = _Updater
		? "https://codeberg.org/api/v1/repos/ltguillaume/librewolf-winupdater/releases/latest"
		: "https://gitlab.com/api/v4/projects/44042130/releases/permalink/latest")
	ReleaseInfo := Download(ReleaseUrl)
	If (!ReleaseInfo)
		Die(_DownloadJsonError)

	RegExMatch(ReleaseInfo, "i)tag_name"":""v?(.+?)""", Release)
	LatestVersion := Release1
	If (!LatestVersion)
		Die(_JsonVersionError)

	Return LatestVersion
}

GuiClose() {
	Gui, Destroy
	Exit()
}

Hash(filePath, hashType = 4) {
; https://www.autohotkey.com/board/topic/66139-ahk-l-calculating-md5sha-checksum-from-file/
	PROV_RSA_AES := 24
	CRYPT_VERIFYCONTEXT := 0xF0000000
	BUFF_SIZE := 1024 * 1024	; 1MB
	HP_HASHVAL := 0x0002
	HP_HASHSIZE := 0x0004

	HASH_ALG := hashType = 1 ? (CALG_MD2 := 32769) : HASH_ALG
	HASH_ALG := hashType = 2 ? (CALG_MD5 := 32771) : HASH_ALG
	HASH_ALG := hashType = 3 ? (CALG_SHA := 32772) : HASH_ALG
	HASH_ALG := hashType = 4 ? (CALG_SHA_256 := 32780) : HASH_ALG
	HASH_ALG := hashType = 5 ? (CALG_SHA_384 := 32781) : HASH_ALG
	HASH_ALG := hashType = 6 ? (CALG_SHA_512 := 32782) : HASH_ALG

	f := FileOpen(filePath, "r", "CP0")
	If (!IsObject(f))
		Return 0

	If (!hModule := DllCall("GetModuleHandleW", "str", "Advapi32.dll", "Ptr"))
		hModule := DllCall("LoadLibraryW", "str", "Advapi32.dll", "Ptr")

	If (!DllCall("Advapi32\CryptAcquireContextW"
			,"Ptr*", hCryptProv
			,"Uint", 0
			,"Uint", 0
			,"Uint", PROV_RSA_AES
			,"UInt", CRYPT_VERIFYCONTEXT))
		Goto, FreeHandles

	If (!DllCall("Advapi32\CryptCreateHash"
			, "Ptr",  hCryptProv
			, "Uint", HASH_ALG
			, "Uint", 0
			, "Uint", 0
			, "Ptr*", hHash))
		Goto, FreeHandles

	VarSetCapacity(read_buf, BUFF_SIZE, 0)
	hCryptHashData := DllCall("GetProcAddress", "Ptr", hModule, "AStr", "CryptHashData", "Ptr")

	While (cbCount := f.RawRead(read_buf, BUFF_SIZE)) {
		If (cbCount = 0)
			Break

		If (!DllCall(hCryptHashData
				, "Ptr",  hHash
				, "Ptr",  &read_buf
				, "Uint", cbCount
				, "Uint", 0))
			Goto, FreeHandles
	}

	If (!DllCall("Advapi32\CryptGetHashParam"
			, "Ptr",   hHash
			, "Uint",  HP_HASHSIZE
			, "Uint*", HashLen
			, "Uint*", HashLenSize := 4
			, "UInt",  0))
		Goto, FreeHandles

	VarSetCapacity(pbHash, HashLen, 0)
	If (!DllCall("Advapi32\CryptGetHashParam"
			, "Ptr",   hHash
			, "Uint",  HP_HASHVAL
			, "Ptr",   &pbHash
			, "Uint*", HashLen
			, "UInt",  0))
		Goto, FreeHandles

	SetFormat, Integer, Hex
	Loop, %HashLen%
	{
		num := NumGet(pbHash, A_Index - 1, "UChar")
		hashVal .= SubStr((num >> 4), 0) . substr((num & 0xf), 0)
	}
	SetFormat, Integer, D

FreeHandles:
	f.Close()
	DllCall("FreeLibrary", "Ptr", hModule)
	DllCall("Advapi32\CryptDestroyHash", "Ptr", hHash)
	DllCall("Advapi32\CryptReleaseContext", "Ptr", hCryptProv, "UInt", 0)
	Return hashVal
}

Log(Key, Msg = "", PrefixTime = False) {
	Msg := StrReplace(Msg, "{Task}", Task)
	If (PrefixTime) {
		FormatTime, CurrentTime
		Msg := CurrentTime " " Msg
	}
	IniWrite, %Msg%, %IniFile%, Log, %Key%
}

Notify(Msg, Ver = 0, Delay = 0) {
	If (!Ver)
		Ver := NewVersion
	Menu, Tray, Tip, %Msg%
	If (Scheduled Or Delay) {
		Gui, Destroy
		TrayTip, %Msg%, v%Ver%,, 16
		Sleep, %Delay%
	}
}

Progress(Msg, Ended = False) {
	GuiControl,, LogField, % SubStr(Msg, InStr(Msg, "`n") + 1)
	If (Ended)
		GuiControl,, Progress, 100
	Else
		GuiControl,, Progress, +25
	Menu, Tray, Tip, %Msg%
}

ShowGui() {
	mode := WinExist("ahk_id " + GuiHwnd) ? "NA" : "Minimize"
	Gui, Show, AutoSize %mode%
	If (!WinActive("ahk_id " + GuiHwnd))
		Gui, Flash
	WinWaitClose, ahk_id %GuiHwnd%
}

TaskCheck() {
	RunWait schtasks.exe /query /tn "%_Updater% (%A_UserName%)",, Hide
	GuiControl,, TaskSetField, % ErrorLevel = 0
	Gui, Submit, NoHide
}

TaskSet() {
	If (SettingTask) {
		Progress("")
		If (A_Args[1] = "/CreateTask")
			TaskSetField := 0
		Else If (A_Args[1] = "/RemoveTask")
			TaskSetField := 1
		Sleep, 1000
	}

	Script := A_ScriptDir "\" (TaskSetField = 0 ? TaskCreateFile : TaskRemoveFile)
	GuiControl,, TaskSetField, -1
	RunWait, powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%Script%"
	WinWaitActive, ahk_id %GuiHwnd%
	Sleep, 1000
	WinWaitActive
	TaskCheck()

	If (SettingTask) {
		SettingTask := 0
		ShowGui()	; Don't start updating, just wait for close
	}
}

Unelevate(prms*) {
	If (!A_IsAdmin Or IsPortable Or Scheduled)
		Return

	; ShellRun(prms*) from AutoHotkey's Installer.ahk
	Try {
    shellWindows := ComObjCreate("Shell.Application").Windows
    VarSetCapacity(_hwnd, 4, 0)
    desktop := shellWindows.FindWindowSW(0, "", 8, ComObj(0x4003, &_hwnd), 1)
    if ptlb := ComObjQuery(desktop
        , "{4C96BE40-915C-11CF-99D3-00AA004AE837}"  ; SID_STopLevelBrowser
        , "{000214E2-0000-0000-C000-000000000046}") ; IID_IShellBrowser
    {
        if DllCall(NumGet(NumGet(ptlb+0)+15*A_PtrSize), "ptr", ptlb, "ptr*", psv:=0) = 0
        {
            VarSetCapacity(IID_IDispatch, 16)
            NumPut(0x46000000000000C0, NumPut(0x20400, IID_IDispatch, "int64"), "int64")
            DllCall(NumGet(NumGet(psv+0)+15*A_PtrSize), "ptr", psv
                , "uint", 0, "ptr", &IID_IDispatch, "ptr*", pdisp:=0)
            shell := ComObj(9,pdisp,1).Application
            shell.ShellExecute(prms*)
            ObjRelease(psv)
        }
        ObjRelease(ptlb)
    }
    ExitApp
	} Catch e
		Die(_IsElevated)
}