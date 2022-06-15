; LibreWolf WinUpdater - https://github.com/ltGuillaume/LibreWolf-WinUpdater
;@Ahk2Exe-SetFileVersion 1.4.0

;@Ahk2Exe-Bin Unicode 64*
;@Ahk2Exe-SetDescription LibreWolf WinUpdater
;@Ahk2Exe-SetMainIcon LibreWolf-WinUpdater.ico
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,160`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,206`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,207`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,208`, ,,,,1

ExeFile         := "librewolf.exe"
IniFile         := A_ScriptDir "\LibreWolf-WinUpdater.ini"
ChangesMade     := False
IsPortable      := False
RunningPortable := A_Args[1] = "/Portable"
Verbose         := A_Args[1] <> "/Scheduled"

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
_ChangesMade         = However, new files were written to the LibreWolf folder!
_NoChangesMade       = No changes were made.
_Extracting          = Extracting update for LibreWolf...
_Installing          = Installing update for LibreWolf...
_SilentUpdateError   = Silent update did not complete.`nDo you want to run the interactive installer?
_NewVersionFound     = A new version is available`nClose LibreWolf to start the update
_NoNewVersion        = No new LibreWolf version found
_ExtractionError     = Could not extract archive of portable version.
_MoveToTargetError   = Could not move the following file into the target folder:
_IsUpdated           = LibreWolf has just been updated
_To                  = to

; Preparation
#NoEnv
EnvGet Temp, Temp
OnExit, Exit
FileGetVersion, UpdaterVersion, %A_ScriptFullPath%
UpdaterVersion := SubStr(UpdaterVersion, 1, -2)
Menu, Tray, Tip, %_Title% %UpdaterVersion%
Menu, Tray, NoStandard
Menu, Tray, Add, Portable, About
Menu, Tray, Add, WinUpdater, About
Menu, Tray, Add, Exit, Exit
Menu, Tray, Default, WinUpdater

About(ItemName) {
	Run, https://github.com/ltGuillaume/LibreWolf-%ItemName%
}

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
ReleaseInfo := Download("https://gitlab.com/api/v4/projects/13852981/releases")
If !ReleaseInfo
	Die(_DownloadJsonError)

; Compare versions
RegExMatch(ReleaseInfo, "i)Release v(.+?)""", Release)
NewVersion := Release1
StrReplace(NewVersion, ".",, DotCount)
If DotCount < 2
	NewVersion := NewVersion ".0"
;MsgBox, ReleaseInfo = %ReleaseInfo%`nCurrentVersion = %CurrentVersion%`nNewVersion = %NewVersion%
IniRead, LastUpdateTo, %IniFile%, Log, LastUpdateTo, False
If (NewVersion = CurrentVersion Or NewVersion = LastUpdateTo) {
	If !RunningPortable And Verbose
		Notify(_NoNewVersion, CurrentVersion, 6000)
	IniWrite, %_NoNewVersion%, %IniFile%, Log, LastResult
	Exit
}

; Notify and wait if LibreWolf is running
Process, Exist, %ExeFile%
If ErrorLevel {
	Notify(_NewVersionFound)
	Process, WaitClose, %ExeFile%
	Goto, DownloadInfo
}

; Get setup file URL
FilenameEnd := IsPortable ? "portable.zip" : "setup.exe"
RegExMatch(ReleaseInfo, "i)" FilenameEnd """,""url"":""(.+?windows/+uploads/+.+?\/+(librewolf-.+?" FilenameEnd "))", DownloadUrl)
;MsgBox, Downloading`n%DownloadUrl1%`nto`n%DownloadUrl2%
If !DownloadUrl1 Or !DownloadUrl2
	Die(_FindUrlError)

; Download setup file
If Verbose
	Notify(_Downloading)
SetupFile := DownloadUrl2
UrlDownloadToFile, %DownloadUrl1%, %SetupFile%
If !FileExist(SetupFile)
	Die(_DownloadSetupError)

; Get checksum file
RegExMatch(ReleaseInfo, "i)sha256sums.txt"",""url"":""(.+?windows/+uploads/+.+?/+sha256sums\.txt)", ChecksumUrl)
If !ChecksumUrl1
	Die(_FindSumsUrlError)
Checksum := Download(ChecksumUrl1)

; Get checksum for downloaded file
RegExMatch(Checksum, "i)(\S+?)\s+\Q" SetupFile "\E", Checksum)
If !Checksum1
	Die(_FindChecksumError)

; Compare checksum with downloaded file
If (Checksum1 <> Hash(SetupFile))
	Die(_ChecksumMatchError)

; Extract archive of portable version
If IsPortable {
	If Verbose
		Notify(_Extracting)
	FileRemoveDir, LibreWolf-Extracted, 1
	FileCopyDir, %SetupFile%, LibreWolf-Extracted	; Needs "Zip & Cab folder" (could have been removed by e.g. NTLite)
	If ErrorLevel {	; PowerShell fallback
		FileRemoveDir, LibreWolf-Extracted, 1
		RunWait, powershell.exe -NoProfile -Command "Expand-Archive """%SetupFile%""" LibreWolf-Extracted" -ErrorAction Stop,, Hide
		If ErrorLevel
			Die(_ExtractionError)
	}
	Loop, Files, LibreWolf-Extracted\*, D
	{
;MsgBox, Traversing %A_LoopFilePath%
		If FileExist(A_LoopFilePath "\LibreWolf-WinUpdater.exe")
			FileMove, %A_ScriptFullPath%, %A_ScriptFullPath%.pbak, 1
		SetWorkingDir, %A_LoopFilePath%
		Loop, Files, *, R
		{
			FileGetSize, CurrentFileSize, %A_ScriptDir%\%A_LoopFilePath%
;MsgBox, % A_LoopFilePath "`n" A_LoopFileSize "`n" CurrentFileSize "`n" Hash(A_LoopFilePath) "`n" Hash(A_ScriptDir "\" A_LoopFilePath)
			If !FileExist(A_ScriptDir "\" A_LoopFileDir)
				FileCreateDir, %A_ScriptDir%\%A_LoopFileDir%
			If (!FileExist(A_ScriptDir "\" A_LoopFilePath) Or A_LoopFileSize <> CurrentFileSize Or Hash(A_LoopFilePath) <> Hash(A_ScriptDir "\" A_LoopFilePath)) {
;MsgBox, Moving %A_LoopFilePath%
				FileMove, %A_LoopFilePath%, %A_ScriptDir%\%A_LoopFilePath%, 1
				If Errorlevel
					Die(_MoveToTargetError " " A_LoopFilePath)
				ChangesMade := True
			}
		}
	}
	SetWorkingDir, %Temp%
	Goto, Report
}

; Or run silent setup
If Verbose
	Notify(_Installing)
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
FormatTime, CurrentTime
IniWrite, %CurrentTime%, %IniFile%, Log, LastUpdate
IniWrite, %CurrentVersion%, %IniFile%, Log, LastUpdateFrom
IniWrite, %NewVersion%, %IniFile%, Log, LastUpdateTo
IniWrite, %_IsUpdated% %_From% v%CurrentVersion% %_To% v%NewVersion%., %IniFile%, Log, LastResult
Notify(_IsUpdated, CurrentVersion " " _To " v" NewVersion, RunningPortable ? 0 : 60000)
Exit

; Clean up
Exit:
If RunningPortable
	Run, %A_ScriptDir%\LibreWolf-Portable.exe
FormatTime, CurrentTime
IniWrite, %CurrentTime%, %IniFile%, Log, LastRun
Sleep, 2000
If SetupFile
	FileDelete, %SetupFile%
If IsPortable
	FileRemoveDir, LibreWolf-Extracted, 1
FileDelete, %A_ScriptFullPath%.pbak

Notify(Msg, Ver = 0, Delay = 0) {
	Global NewVersion
	If !Ver
		Ver := NewVersion
	Menu, Tray, Tip, %Msg%
	TrayTip, %Msg%, v%Ver%,, 16
	If Delay
		Sleep, %Delay%
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
	If !IsObject(f)
		Return 0

	If !hModule := DllCall("GetModuleHandleW", "str", "Advapi32.dll", "Ptr")
		hModule := DllCall("LoadLibraryW", "str", "Advapi32.dll", "Ptr")

	If !DllCall("Advapi32\CryptAcquireContextW"
			,"Ptr*", hCryptProv
			,"Uint", 0
			,"Uint", 0
			,"Uint", PROV_RSA_AES
			,"UInt", CRYPT_VERIFYCONTEXT)
		Goto, FreeHandles

	If !DllCall("Advapi32\CryptCreateHash"
			, "Ptr",  hCryptProv
			, "Uint", HASH_ALG
			, "Uint", 0
			, "Uint", 0
			, "Ptr*", hHash)
		Goto, FreeHandles

	VarSetCapacity(read_buf, BUFF_SIZE, 0)
	hCryptHashData := DllCall("GetProcAddress", "Ptr", hModule, "AStr", "CryptHashData", "Ptr")

	While (cbCount := f.RawRead(read_buf, BUFF_SIZE)) {
		If (cbCount = 0)
			Break

		If !DllCall(hCryptHashData
				, "Ptr",  hHash
				, "Ptr",  &read_buf
				, "Uint", cbCount
				, "Uint", 0)
			Goto, FreeHandles
	}

	If !DllCall("Advapi32\CryptGetHashParam"
			, "Ptr",   hHash
			, "Uint",  HP_HASHSIZE
			, "Uint*", HashLen
			, "Uint*", HashLenSize := 4
			, "UInt",  0) 
		Goto, FreeHandles

	VarSetCapacity(pbHash, HashLen, 0)
	If !DllCall("Advapi32\CryptGetHashParam"
			, "Ptr",   hHash
			, "Uint",  HP_HASHVAL
			, "Ptr",   &pbHash
			, "Uint*", HashLen
			, "UInt",  0)
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
	DllCall("Advapi32\CryptReleaseContext", "Ptr", hCryptProv, "UInt",0)
	Return hashVal
}

Die(Error) {
	Global IniFile, ChangesMade, Verbose, _Title, _ChangesMade, _NoChangesMade
	IniWrite, %Error%, %IniFile%, Log, LastResult
	If Verbose
		MsgBox, 48, %_Title%, % Error "`n" (ChangesMade ? _ChangesMade : _NoChangesMade)
	Exit
}