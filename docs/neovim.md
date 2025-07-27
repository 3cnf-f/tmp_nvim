# Vim/Neovim Cheatsheet

This is a tidied version of your notes on Vim/Neovim shortcuts, commands, and features. I've organized them into logical sections, corrected typos (e.g., "endo" to "end"), removed redundancies, and improved clarity while preserving the original content. Custom shortcuts (e.g., leader keys) are kept as-is, assuming they're from your config. I've grouped similar topics and used consistent formatting.

## Basic Grammar and Operators
- **Capitalize for rest of line**: Use uppercase letters like `A` (append at EOL), `I` (insert at BOL), `Y` (yank line).
- **Repeat for rest of line**: `cc` (change line), `yy` (yank line), `dd` (delete line).
- **Inner/around motions**:
  - `iw`: Inside word (e.g., `diw` delete inside word, `yiw` yank inside word).
  - `i"`: Inside quotes (e.g., `di"` delete inside quotes).
  - `a"`: Around quotes (including quotes, e.g., `da"` delete around quotes).

Example: Try on text `"this is a stupid text"`.

## Normal Mode
- `ZZ` save and quit
- `ZQ` DONT save and quit

### Movement
- `gg`: Move to first line of file.
- `#G`: Move to line number #.
- `%`: Move to matching parenthesis/bracket `{[(` when on one.
- `])`: Move to closing `)` when inside.
- `]%`: Move to closing `)]}` when inside.
- `C-f` / `C-b`: Move forward/back one screen.
- `C-d` / `C-u`: Move forward/back half screen.
- `$`: Move to end of line.
- `0`: Move to beginning of line.
- `^`: Move to first non-empty character on line.
- `I`: Insert at first non-empty character.
- `{` / `}`: Jump backward/forward by paragraph.
- `f<char>` / `F<char>`: Forward/backward to `<char>`.
- `t<char>` / `T<char>`: Forward/backward to before `<char>`.
- `;` / `,`: Repeat last `f/F/t/T` forward/backward.
- `*`: Search for next occurrence of current word; `n`/`N` to navigate.
- `gg`: Beginning of file.
- `G`: End of file.

### Jumplist
Certain movements are added to the jumplist (navigate with `C-o` back, `C-i` forward):
- Searching (`/` or `?`).
- Jumping to line number (e.g., `10G`).
- Matching parentheses (`%`).
- Moving between files (e.g., `gf`).

### Scroll Cursor Line (to peek without moving cursor)
- `C-e` / `C-y`: Scroll line up/down.
- `zz`: Center cursor line.
- `zt`: Move cursor line to top.
- `zb`: Move cursor line to bottom.

### Delete, Replace, Change
- `d$`: Delete to end of line.
- `dG`: Delete to end of file.
- `de`: Delete to end of word.
- `dip`: Delete inside paragraph.
- `di}`: Delete inside block/paragraph.
- `cc`: Change whole line.
- `C`: Change to end of line.
- `cip`: Change inside paragraph.
- `ci"`: Change inside quotes.
- `ci}`: Change inside block.
- `r`: Replace single character.
- `R`: Replace mode until ESC.
- `ciw`: Change inside word (delete word and insert).
- `diw`: Delete inside word.
- `diW`: Delete inside WORD (till whitespace).
- `daw`: Delete a word includes whitespace
- `3dd`: Delete 3 lines.
- `d/poop`: Delete until "poop".
- `d0`: Delete to start of line.
- `y3fi`: Yank from cursor to 3rd 'i'.

### Yanking and Pasting
- `yip`: Yank inside paragraph.
- `p` / `P`: Paste after/before cursor.
  - If buffer is a line, pastes on next/previous line.
- `YY`: Yank line.
- `yiw`: Yank inside word.
- Registers:
  - `1p`: Paste from register 1 in normal mode.
  - `C-r 1`: Paste from register 1 in insert mode.
  - `viwp`: Replace word with contents of register 0 (visual select word, paste).
  - `vep`: Replace word (but register changes).

See: [How do I use vim registers? - Stack Overflow](https://stackoverflow.com/questions/1497958/how-do-i-use-vim-registers) (covers macros as registers).

### Undo/Redo
- `u`: Undo.
- `C-r`: Redo.

### Search and Replace
- `%s`: Search/replace in whole file.
- `%s/poop`: Search for "poop".
  - Enter to confirm.
  - `n`/`N` for next/previous.
- `%s/r/t`: Replace first "r" with "t" on each line.
- `%s/r/t/g`: Replace all "r" with "t" on each line.
- `:s/r/t`: Replace in current line.
- Leader `nh`: Clear search highlights.

### Case Switching
- `g~e`: Toggle case to end of word.
- `gU$`: Uppercase to end of line.

### Macros
- `qh`: Record macro to register 'h'.
- `q`: Stop recording.
- `@h`: Play macro in 'h'.
- `.`: Replay last action.

### Visual Modes
- `v`: Visual character mode.
- `V`: Visual line mode.
- `C-v`: Visual block mode.
  - Example: `C-v`, `j/k` to select lines, `I` to insert before (e.g., "-poop-"), ESC to apply.
  - `gv`: Reselect last visual selection.
  - Then `$` to end of lines, add text, ESC to apply.
- `gc`: Toggle comment in visual selection.
- `gcc`: Toggle comment current line.

### Norm Command
- In visual mode, select text then `:norm A);` to append ");" to each line.
- `:norm I print(` to prepend "print(" to each line.

### Comments
- `gc`: Toggle comment (visual or motion).
- `gcc`: Toggle comment line.

## Neovim-Specific (Shell/Leader Shortcuts)
- Space `tr`: Toggle line numbers.
- `-`: Start Oil file manager.
- Leader `+` / `-`: Increment/decrement number under cursor.

### Window Management
- Leader `sv`: Split vertically.
- Leader `sh`: Split horizontally.
- Leader `se`: Equalize splits.
- Leader `sx`: Close current split.
- `C-w n`: New buffer in split.
- `C-w hjkl`: Navigate windows.

### Tab Management
- Leader `to`: Open new tab.
- Leader `tx`: Close current tab.
- Leader `tn`: Next tab.
- Leader `tp`: Previous tab.
- Leader `tf`: Open current buffer in new tab.

### Surround Plugin
See: [nvim-surround wiki](https://github.com/kylechui/nvim-surround/wiki/getting-started-for-beginners)
- `ysiwf`: Surround word with function (prompts for name, e.g., parentheses).
- `dsf`: Delete surrounding function.
- `ysa"f`: Surround quotes with function.
- `ysw"`: Surround word with quotes.
- `ds]`: Delete surrounding ].
- `cs]}`: Replace ] with }.
- `di"`: Delete inside quotes.

### Oil File Manager
- `g.`: Show hidden files.
- `?`: Help.

## Neovim in VSCode
- `C-A-a`: Codeium toggle chat.
- Shift+Ctrl `up/down`: VSCode multiline cursor.
- Shift+`E`: Exit multiline.
- Added to user settings JSON:
  - `H` / `L`: Focus previous/next tab.
  - `Q`: Close tab.
  - `C-w v` / `|`: Split vertical.
  - `C-w s` / `_`: Split horizontal.
- Shift+Alt `A`: Toggle block comment.
- Ctrl `'`: Toggle line comment.
- Commands: Toggle indentation to spaces, refresh extensions, toggle whitespace.

## Additional Resources
- [Vim Cheat Sheet](/vim-cheat.png)
