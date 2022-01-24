<a href="https://buymeacoff.ee/ltGuillaume"><img title="Donate using Buy Me a Coffee" src="https://raw.githubusercontent.com/ltGuillaume/Resources/master/buybeer.svg"></a> <a href="https://liberapay.com/ltGuillaume/donate"><img title="Donate using Liberapay" src="https://raw.githubusercontent.com/ltGuillaume/Resources/master/liberapay.svg"></a>

<img src="https://raw.githubusercontent.com/ltGuillaume/LibreWolf-WinUpdater/master/LibreWolf-WinUpdater.ico" align="right"/>

# LibreWolf WinUpdater

[LibreWolf WinUpdater](https://github.com/ltGuillaume/LibreWolf-WinUpdater) by ltGuillaume  
[LibreWolf](https://librewolf.net) by [ohfp](https://gitlab.com/ohfp), [stanzabird](https://stanzabird.nl), [fxbrit](https://gitlab.com/fxbrit), [maltejur](https://gitlab.com/maltejur), [bgstack15](https://bgstack15.wordpress.com) et al.

An attempt to make updating LibreWolf for Windows much easier.

## Getting started
1. Having installed LibreWolf, you can run `LibreWolf-WinUpdater.exe` to check for a new version, then download and install it immediately. If LibreWolf is running, the updater will notify you of the new version, and update as soon as you close the browser (again, notifying you). The last result can be found in `LibreWolf-WinUpdater.ini`.
2. Afterwards, you can right-click on `ScheduledTask-Create.ps1` and choose `Run with PowerShell` to create a scheduled task that checks for updates every 4 hours, and at logon. When run from a scheduled task, error messages will only be saved in  `LibreWolf-WinUpdater.ini` (no dialogs will be shown). The updater will now run as administrator, so that the installer can be run silently.
3. You can remove the scheduled task by running `ScheduledTask-Remove.ps1`.

## Credits
* Icon by the [LibreWolf Community](https://gitlab.com/librewolf-community/branding/-/tree/master/icon)