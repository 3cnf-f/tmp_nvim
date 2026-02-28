* stick .wezterm.lua in %USERPROFILE%
* stick init.lua in %USERPROFILE%\APPDATA\local\nvim
# Time fd
  Measure-Command { H:\007git\bin\fd.exe --color=never --type f --extension txt --extension md H:\dokument\ | Measure-Object -Line }

# Time rg
  Measure-Command { H:\007git\bin\rg.exe --files --glob "*.{txt,md}" H:\dokument\ | Measure-Object -Line }

```
function Format-Human {
    param(
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )

    process {
        $text = if ($InputObject -is [string]) { $InputObject } else { $InputObject | Out-String }

        # Prepends markers exactly as you asked, keeps visual layout
        $text = $text `
            -replace "`r`n", " ((13,10))`r`n" `
            -replace "`r(?!\n)", " ((13))`r" `
            -replace "(?<!`r)`n", " ((10))`n" `
            -replace "`v", " ((11))" `
            -replace "`f", " ((12))"

        $text
    }
}
```
