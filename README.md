<img src="LibreWolf-WinUpdater.ico" align="right">

# LibreWolf WinUpdater
by ltGuillaume: [Codeberg](https://codeberg.org/ltGuillaume) | [GitHub](https://github.com/ltGuillaume) | [Buy me a beer](https://buymeacoff.ee/ltGuillaume) 🍺

An attempt to make updating LibreWolf for Windows much easier.

![LibreWolf WinUpdater](SCREENSHOT.png)

## Getting started
- If you want to run the portable version of LibreWolf, download and extract [`librewolf-xxx.x.x-windows-x86_64-portable.zip`](https://librewolf.net/installation/windows/) (second blue button). It already contains a compiled version of the project hosted here.  
  LibreWolf will be updated automatically whenever you run `LibreWolf-Portable.exe`  (checks for new versions happen once a day). If you wish to perform update checks manually instead, just rename WinUpdater to e.g. `LibreWolf-ManualUpdater.exe` and run it when needed.
- When installing LibreWolf, the [official installer](https://librewolf.net/installation/windows/) will show an option to install WinUpdater.  
  Alternatively, you can download and extract the latest [`LibreWolf-WinUpdater_x.x.x.zip`](https://codeberg.org/ltGuillaume/LibreWolf-WinUpdater/releases) to a folder you like, e.g. `%AppData%\LibreWolf`. Run `LibreWolf-WinUpdater.exe` to check for an update. If one is available, it will be downloaded immediately.
- LibreWolf WinUpdater also updates itself automatically, so you won't have to check for new releases here.

## Scheduled updates
- Run LibreWolf WinUpdater and select the option to automatically check for updates. This will prompt for administrator permissions and a blue (PowerShell) window will notify you of the result. The scheduled task will run while the current user account is logged on (at start-up and every 4 hours).
- If your account has administrator permissions, the update will be fully automatic. If not, the update will be downloaded and you will be asked by WinUpdater to start the update (administrator permissions required).  
- If LibreWolf is already running, the updater will notify you of the new version. The update will start as soon as you close the browser.

## Remarks
- If you're having issues with the updater on __Windows 7__  (not officially supported by LibreWolf anymore), please have a look at [these instructions](https://codeberg.org/ltGuillaume/LibreWolf-WinUpdater/issues/15).
- The updater needs to be able to write to `LibreWolf-WinUpdater.ini` in its own folder, (so make sure it has permission to do so), otherwise WinUpdater will copy itself to `%AppData%\LibreWolf\WinUpdater` and run from there.
- `LibreWolf-WinUpdater.ini` contains a `[Log]` section that shows the results of the last update check and update action.

## Credits
* [LibreWolf](https://librewolf.net) by [ohfp](https://gitlab.com/ohfp), [stanzabird](https://stanzabird.nl), [fxbrit](https://gitlab.com/fxbrit), [maltejur](https://gitlab.com/maltejur), [bgstack15](https://bgstack15.wordpress.com) et al.
* Original icon by the [LibreWolf Community](https://gitlab.com/librewolf-community/branding/-/tree/master/icon)
