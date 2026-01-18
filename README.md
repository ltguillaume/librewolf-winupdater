<img src="LibreWolf-WinUpdater.ico" align="right">

# LibreWolf WinUpdater
by ltGuillaume: [Codeberg](https://codeberg.org/ltguillaume) | [GitHub](https://github.com/ltguillaume) | [Buy me a beer](https://coff.ee/ltguillaume) 🍺

An attempt to make updating LibreWolf for Windows much easier.

![LibreWolf WinUpdater](SCREENSHOT.png)

## Getting started
- If you want to run the portable version of LibreWolf, download and extract [`librewolf-xxx.x.x-windows-x86_64-portable.zip`](https://librewolf.net/installation/windows/) (second blue button). It already contains a compiled version of the project hosted here.  
  LibreWolf will be updated automatically whenever you run `LibreWolf-Portable.exe`  (checks for new versions happen once a day). If you wish to perform update checks manually instead, just rename WinUpdater to e.g. `LibreWolf-ManualUpdater.exe` and run it when needed.
- When installing LibreWolf, the [official installer](https://librewolf.net/installation/windows/) will show an option to install WinUpdater. On first run, it will copy itself to `%AppData%\LibreWolf\WinUpdater` to be able to update itself without administrator privileges.  
  Alternatively, you can download and extract the latest [`LibreWolf-WinUpdater_x.x.x.zip`](https://codeberg.org/ltguillaume/librewolf-winupdater/releases) to a like `%AppData%\LibreWolf\WinUpdater`. Run `LibreWolf-WinUpdater.exe` to check for an update. If one is available, it will be downloaded immediately.

## Scheduled updates
- Run LibreWolf WinUpdater and select the option to automatically check for updates. This will prompt for administrator permissions and a blue (PowerShell) window will notify you of the result. The scheduled task will run while the current user account is logged on (at start-up and every 4 hours).
- If your account has administrator permissions, the update will be fully automatic. If not, the update will be downloaded and you will be asked by WinUpdater to start the update (administrator permissions required).  
- If LibreWolf is already running, the updater will notify you of the new version. The update will start as soon as you close the browser.

## Issues
- If you set up scheduled updates, you might get annoyed by some __anti-cheat software__. It may wrongfully point at WinUpdater, because it is built upon AutoHotkey, which _can_ be used to cheat in games. If this happens, you can either:
  1. Open the __Task Scheduler__ via the Start menu, then double-click on `LibreWolf WinUpdater...` in the `Task Scheduler Library`, open the `Triggers` tab, then click on `One time` and the button `Delete`. Then press `OK` to make the change to _only check for updates 1 minute after logging on_ (and not every 4 hours). This will still cause issues if you leave games opened when locking your user account, though.
  2. Create a shortcut to `%AppData%\LibreWolf\WinUpdater\LibreWolf-Winupdater.exe /RemoveTask` and one to `%AppData%\LibreWolf\WinUpdater\LibreWolf-Winupdater.exe /CreateTask` (on your desktop), so you can quickly prevent WinUpdater from running during gameplay and reactivate it afterwards. Just put them next to the shortcuts of your game launchers and you won't forget.

## Remarks
- If you're having issues with the updater on __Windows 7__  (not officially supported by LibreWolf anymore), please have a look at [these instructions](https://codeberg.org/ltguillaume/librewolf-winupdater/issues/15).
- The updater needs to be able to write to `LibreWolf-WinUpdater.ini` in its own folder, (so make sure it has permission to do so), otherwise WinUpdater will copy itself to `%AppData%\LibreWolf\WinUpdater` and run from there.
- `LibreWolf-WinUpdater.ini` contains a `[Log]` section that shows the results of the last update check and update action.
- Windows may show a `Security Alert: Revocation information for the Security certificate for this site is not available` dialog _without the context that WinUpdater tried to make this connection_. This can happen because you have enabled the non-default option `Check for server certificate revocation` in the Windows `Internet Options` (tab `Advanced`). However, WinUpdater should show you a dialog on top of that, asking you if you still want to continue. If this happens often, you can tell WinUpdater to automatically continue when this dialog pops up by setting `IgnoreCrlErrors` to `1` in the .ini file under `[Settings]`:
  ```ini
  [Settings]
  IgnoreCrlErrors=1
  ```
- LibreWolf WinUpdater also updates itself automatically, so you won't have to check for new releases here. If you prefer to update it manually, set `UpdateSelf` to `0` in the .ini file under `[Settings]`:
  ```ini
  [Settings]
  UpdateSelf=0
  ```
- If for some reason WinUpdater is not able to use the user's default `%Temp%` folder for downloading and extracting files, you can specify an alternative working directory by setting `WorkDir` in the .ini file under `[Settings]`:
  ```ini
  [Settings]
  WorkDir=D:\Temp
  ```
  To specify the directory of `LibreWolf-WinUpdater.exe`, type `WorkDir=.`.

## Credits
* [LibreWolf](https://librewolf.net) by the [LibreWolf Community](https://librewolf.net/#core-contributors)
* [Original icon](https://codeberg.org/librewolf/branding) by the [LibreWolf Community](https://librewolf.net/#core-contributors)
