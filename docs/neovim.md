# Neovim Reference — Swedish Keyboard Edition

**Leader:** Space
**Platform notes:** 🐧 = Linux only  ✦ = both platforms

---

## 1. The Swedish Triad

### `ä` = Attention (Flash jumps) ✦

| Key | Action |
|-----|--------|
| `ä` | Jump to any visible word/char (label appears, type to land) |
| `Ä` | Treesitter select — labels AST nodes (functions, classes, loops) |
| `dä` / `yä` / `cä` | Delete / yank / change at a flash-selected position |
| `r` *(op-pending)* | Remote flash — apply operator at another position, cursor stays |
| `R` *(op-pending/visual)* | Treesitter search — jump and select matching AST node |
| `<C-s>` *(cmd mode)* | Overlay flash labels on top of a running `/` search |

### `ö` = Orientation (structure navigation) 🐧

Requires treesitter parsers. Lowercase = next, uppercase = previous.

| Key | Action |
|-----|--------|
| `ön` / `öp` | Next / Prev function |
| `öc` / `öC` | Next / Prev class |
| `öl` / `öL` | Next / Prev loop |
| `öi` / `öI` | Next / Prev conditional |
| `öf` / `öb` | Next / Prev paragraph (`}` / `{`) |

### `Ö` = Append-and-stay ✦

Waits for one character, inserts it after the cursor char, cursor stays put.

| Key | Action |
|-----|--------|
| `Ö<char>` | Insert `<char>` after cursor character, return to position |
| `Ö<Space>` | Insert space after cursor char (`helloworld` → `hello world`) |
| `Ö<Enter>` | Split line after cursor char, cursor stays on original line |
| `Ö<Esc>` | Abort, no change |

### `å` = Actions (debugger) 🐧

Requires `pip install debugpy`.

| Key | Action |
|-----|--------|
| `åc` | Continue / Start session |
| `åb` | Toggle breakpoint |
| `åB` | Conditional breakpoint (prompts for condition) |
| `å1` | Step over |
| `åi` | Step into |
| `åo` | Step out |
| `åu` | Toggle DAP UI |
| `åx` | Terminate + close UI |
| `åR` | Restart session |
| `år` | Open REPL console |
| `åh` | Hover — show variable value under cursor |
| `åe` | Evaluate expression (prompts) |
| `åe` *(visual)* | Evaluate selection |
| `åV` | Toggle inline virtual text (variable values at EOL) |
| `åw` | Add watch expression |
| `åv` | Float scopes panel |
| `åW` | Float watches panel |
| `åS` | Float call stack panel |
| `ådf` | Dump variable to `/tmp/dump_<var>.txt` |
| `åds` | Dump variable → open in vertical split |
| `ådt` | Dump variable → open in new tab |
| `ådv` | Dump variable → send to remote nvim socket |
| `åt` | Start nvim socket server in tmux (`/tmp/nvimsocket`) |

### `Å` = REPL (Iron + tmux) 🐧

Requires `pip install ipython`. Run inside tmux for external target mode.

| Key | Action |
|-----|--------|
| `Åt` | Toggle REPL / create tmux window |
| `Åä` | Toggle target: Internal (Iron split) ↔ External (tmux window) |
| `Åss` | Send current line |
| `Åsb` | Send current paragraph block |
| `Åsf` | Send whole file |
| `Ås` + motion | Send motion (e.g. `Åsiw` sends inner word) |
| `Ås` *(visual)* | Send selection |
| `År` | Restart REPL / ipython session |
| `Åf` | Focus REPL window |
| `Åh` | Hide REPL window |
| `Åc` | Clear REPL screen |

Terminal mode (inside REPL split):

| Key | Action |
|-----|--------|
| `<Esc><Esc>` | Exit terminal mode → normal mode |
| `<M-Arrow>` | Jump between splits (same as normal mode) |

---

## 2. AI Completion (Neocodeium) 🐧

Ghost-text suggestions while typing. Run `:NeoCodeium auth` on first use.

| Key | Mode | Action |
|-----|------|--------|
| `<A-l>` | insert | Accept full suggestion |
| `<A-j>` | insert | Next suggestion |
| `<A-k>` | insert | Previous suggestion |
| `<A-h>` | insert | Clear suggestion |
| `<A-c>` | insert | Cycle or complete |
| `<A-o>` | insert | Accept next word |
| `<A-ö>` | insert | Accept next word (Swedish alias) |
| `<A-p>` | insert | Accept next line |
| `<A-f>` | insert | Accept full suggestion (alias) |

---

## 3. LSP — Python (Jedi) 🐧

Requires `pip install jedi-language-server`. Auto-attaches to `.py` files.

Buffer-local (active when LSP is attached):

| Key | Action |
|-----|--------|
| `gd` | Go to definition (fzf-lua) |
| `gr` | Go to references (fzf-lua) |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |

Global LSP extras:

| Key | Action |
|-----|--------|
| `<leader>cj` | Jump to definition (fzf-lua) |
| `<leader>cr` | References (fzf-lua) |
| `<leader>ca` | Code actions (floating picker) |
| `<leader>cd` | Document diagnostics |
| `<leader>cs` | Document symbols |
| `<leader>cp` | Peek definition (preview, no jump) |

---

## 4. Completion Menu (nvim-cmp) 🐧

Appears automatically. Sources: LSP → Codeium → buffer words → file paths.

| Key | Action |
|-----|--------|
| `<C-Space>` | Force open menu |
| `<Tab>` / `<S-Tab>` | Navigate down / up |
| `<CR>` | Confirm selection |

---

## 5. Search & Files

### FZF-Lua 🐧

| Key | Action |
|-----|--------|
| `<leader>p` | Find files |
| `<leader>f` | Live grep |
| `<leader><leader>` | Resume last picker |
| `<leader>b` | Open buffers |
| `<leader>7` | Grep word under cursor |
| `<leader>8` *(visual)* | Grep selection |
| `<leader>r` | Registers |
| `<leader>m` | Marks |
| `<leader>k` | All keymaps |
| `<leader>K` | Buffer-local keymaps |
| `<leader>j` | Help tags |
| `<leader>s` | Spell suggestions |
| `<leader>gs` | Git status |
| `<leader>gc` | Git file commits |

### Windows alternatives ✦

| Key | Action |
|-----|--------|
| `<leader>k` / `<leader>K` | Scratch buffer keymap list (search with `/`) |
| `<leader>b` | Scratch buffer list (`<CR>` to switch, `q` to close) |
| `<leader>r` | `:registers` |
| `<leader>m` | `:marks` |
| `<leader>s` | `z=` spell suggest |
| `<leader>j` | `:help ` prefilled |

### Oil (file manager) ✦

| Key | Action |
|-----|--------|
| `-` | Open parent directory in float |
| `g.` | Toggle hidden files |
| `<CR>` | Open file / enter directory |

---

## 6. Surround (nvim-surround) ✦

| Key | Action |
|-----|--------|
| `ysiw"` | Surround inner word with `"` |
| `yss(` | Surround whole line with `()` |
| `yS2j{` | Surround 2 lines linewise with `{}` (indented) |
| `ySiw[` | Surround inner word linewise with `[]` (indented) |
| `ySS(` | Surround current line linewise with `()` |
| `cs"'` | Change surrounding `"` → `'` |
| `cs({` | Change surrounding `(` → `{` |
| `cst"` | Change surrounding tag → `"` |
| `ds"` | Delete surrounding `"` |
| `ds(` | Delete surrounding `()` |
| `dsf` | Delete surrounding function call |
| `S{` *(visual line)* | Surround selection with `{}` |
| `gS{` *(visual line)* | Surround selection linewise with `{}` (indented) |

Note: `(` adds inner spaces, `)` does not. Same for `[`/`]` and `{`/`}`.

---

## 7. Clipboard (system) ✦

| Key | Mode | Action |
|-----|------|--------|
| `<M-y>` + motion | normal | System yank (e.g. `<M-y>iw`) |
| `<M-y><M-y>` | normal | System yank whole line |
| `<M-Y>` | normal | System yank to end of line |
| `<M-y>` | visual | System yank selection |

### x0b line-break normaliser ✦

When active, every system yank (`<M-y>`) converts all line-break variants to `\x0b`
(Word's Shift+Enter soft line break) so pasted text lands as one paragraph in Word.

Default: **ON** on Windows, **OFF** on Linux.

| Key / Command | Action |
|---------------|--------|
| `<leader>tl` | Toggle x0b conversion |
| `:ToggleX0b` | Same |
| `x0b` badge in statusline | Shows when active |

---

## 8. Treesitter text objects 🐧

Use with `d`, `c`, `y`, `v` or any operator.

| Key | Object | Example |
|-----|--------|---------|
| `af` / `if` | Function (around / inner) | `dif` delete body only |
| `ac` / `ic` | Class | `yac` yank whole class |
| `aa` / `ia` | Argument/parameter | `cia` change argument |
| `al` / `il` | Loop | `dal` delete loop |
| `ai` / `ii` | Conditional | `vii` select inside if |

---

## 9. Argument swapper (iswap) 🐧

| Key | Action |
|-----|--------|
| `cx` | Pick two items to swap (labels appear on all swappable items) |
| `cX` | Swap item under cursor with a chosen target |

---

## 10. DevDocs browser ✦

Opens devdocs.io scoped to the current filetype.

| Key / Command | Action |
|---------------|--------|
| `<leader>h` | Look up word under cursor |
| `:Fdd <query>` | Look up a specific term |

---

## 11. Database UI (dadbod) ✦

| Key / Command | Action |
|---------------|--------|
| `<leader>D` | Toggle DBUI drawer |
| `:DBUIAddConnection` | Add a database connection |
| `:DBUIFindBuffer` | Find a SQL buffer in the tree |

SQL files get cmp completions from the connected DB schema.

---

## 12. FTmux — run files in tmux 🐧

| Key | Action |
|-----|--------|
| `<leader>RT` | Run current file |
| `<leader>RM` | Run `main.py` at project root |
| `<leader>RA` | Run `interface/app.py` at project root |

---

## 13. Window & tab management ✦

### Splits

| Key | Action |
|-----|--------|
| `<leader>sv` | Split vertical |
| `<leader>sh` | Split horizontal |
| `<leader>se` | Equalise split sizes |
| `<leader>sx` | Close split |
| `<M-Left/Down/Up/Right>` | Move focus between splits |

### Tabs

| Key | Action |
|-----|--------|
| `<leader>to` | New tab |
| `<leader>tx` | Close tab |
| `<leader>tn` / `<leader>tp` | Next / Prev tab |
| `<leader>tf` | Open current buffer in new tab |

---

## 14. Misc editing ✦

| Key | Action |
|-----|--------|
| `<leader>nh` | Clear search highlights |
| `<leader>tr` | Toggle relative line numbers |
| `<leader>+` / `<leader>-` | Increment / decrement number (normal + visual) |
| `g<leader>+` *(visual block)* | Sequential increment column |
| `g<leader>-` *(visual block)* | Sequential decrement column |
| `gx` | Open URL / path under cursor |

---

## 15. Macros & registers ✦

| Key | Action |
|-----|--------|
| `qa` | Record macro to register `a` |
| `q` | Stop recording |
| `@a` | Play macro `a` |
| `@@` | Replay last macro |
| `<C-r>a` *(insert)* | Paste register `a` |
| `"0p` | Paste last yank (ignores deletes) |

---

## 16. Core motions (built-in) ✦

| Key | Action |
|-----|--------|
| `gg` / `G` | Start / End of file |
| `^` / `$` | First non-blank / end of line |
| `g_` | Last non-blank of line |
| `%` | Jump to matching bracket |
| `<C-d>` / `<C-u>` | Scroll down / up half page |
| `<C-o>` / `<C-i>` | Jump back / forward in jumplist |
| `A` / `I` | Append at EOL / insert at start |
| `o` / `O` | New line below / above |
| `r` | Replace single character |
| `J` | Join line below to current |
