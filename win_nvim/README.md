* stick .wezterm.lua in %USERPROFILE%
* stick init.lua in %USERPROFILE%\APPDATA\local\nvim
# Time fd
  Measure-Command { H:\007git\bin\fd.exe --color=never --type f --extension txt --extension md H:\dokument\ | Measure-Object -Line }

# Time rg
  Measure-Command { H:\007git\bin\rg.exe --files --glob "*.{txt,md}" H:\dokument\ | Measure-Object -Line }

```
(Get-Clipboard -Raw) -replace "`r`n", "`r`n((13,10))" -replace "`r", "`r((13))" -replace "`n", "`n((10))" -replace "`v", "`v((11))" -replace "`f", "`f((12))"
```
