<a href="https://buymeacoff.ee/ltGuillaume"><img title="Donate using Buy Me a Coffee" src="https://raw.githubusercontent.com/ltGuillaume/Resources/master/buybeer.svg"></a> <a href="https://liberapay.com/ltGuillaume/donate"><img title="Donate using Liberapay" src="https://raw.githubusercontent.com/ltGuillaume/Resources/master/liberapay.svg"></a>

<img src="https://raw.githubusercontent.com/ltGuillaume/LibreWolf-WinUpdater/master/LibreWolf-WinUpdater.ico" align="right"/>

# LibreWolf WinUpdater

[LibreWolf WinUpdater](https://github.com/ltGuillaume/LibreWolf-WinUpdater) by ltGuillaume  
[LibreWolf](https://librewolf.net) by [ohfp](https://gitlab.com/ohfp), [stanzabird](https://stanzabird.nl), [fxbrit](https://gitlab.com/fxbrit), [maltejur](https://gitlab.com/maltejur), [bgstack15](https://bgstack15.wordpress.com) et al.

An attempt to make updating LibreWolf for Windows much easier.

## Getting started
- Run `LibreWolf-WinUpdater.exe` to check for an update for the installed LibreWolf version. It will then be downloaded and installed immediately.  
  If LibreWolf is running, the updater will notify you of the new version, and update as soon as you close the browser. The last result can be found in `LibreWolf-WinUpdater.ini`.  
- If you place `LibreWolf-WinUpdater.exe` in the same folder as `LibreWolf-Portable.exe`, it will update the __portable version__ instead.  
  _The updater depends on PowerShell to extract the contents of the portable version's zip-file._

## Scheduled updates
- You can right-click on `ScheduledTask-Create.ps1` and choose `Run with PowerShell` to create a scheduled task (for the current user account) that checks for updates every 4 hours, and at logon.  
  When run from a scheduled task, _error_ messages will only be saved in  `LibreWolf-WinUpdater.ini` (no dialogs will be shown).  
  The updater will now run as administrator, so the installer can be run silently.  
  __Warning__: In order to run PowerShell scripts, the Execution Policy should set to at least _RemoteSigned_ (`Set-ExecutionPolicy RemoteSigned`). The included scripts try to automatically do that. You can reset this policy in an elevated PowerShell window by typing `Set-ExecutionPolicy Default` and `Y`.
- You can remove the scheduled task by right-clicking on `ScheduledTask-Remove.ps1` and choosing `Run with PowerShell`.

## Remarks
- The updater needs to be able to write to `LibreWolf-WinUpdater.ini` in its own folder, so make sure it's got permission to do so.
- The ini-file contains the last result of checking for updates and the last update action.

## Credits
* Icon by the [LibreWolf Community](https://gitlab.com/librewolf-community/branding/-/tree/master/icon)