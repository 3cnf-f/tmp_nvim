# 🇸🇪 Neovim Master Reference: The "Kung Fu" Edition
*Windows build — WezTerm + portable git. Leader key: `Space`*

> **Quick keymap search:** `<leader>k` → fuzzy-search all keymaps by description.
> `<leader>K` → same, but only keymaps active for the current buffer / plugin.
> All descriptions use `[tag]` prefixes: `[flash]`, `[oil]`, `[fzf]`, `[surround]`, `[comment]`, `[win]`, `[tab]`, `[clip]`, `[edit]`.

---

## 0. The Swedish Triad

Three special keys on the Swedish keyboard repurposed as power prefixes.

### `ä` — Attention (Flash jump)
*`s`/`S` are freed for nvim-surround; `ä` takes over Flash.*

| Key | What it does |
| :--- | :--- |
| **`ä`** | **Flash jump** — labels every word on screen; type label chars to teleport there. |
| **`Ä`** | **Flash + treesitter** — same but labels whole AST nodes (functions, blocks, classes). |
| **`dä`** | **Delete remote** — press `dä`, jump to any word, delete it without moving cursor first. |
| **`yä`** | **Yank remote** — yank text at any visible location into the register. |
| **`cä`** | **Change remote** — jump somewhere, land in insert mode. |
| **`r`** *(op-pending)* | **Remote operator** — apply any operator at a flash-selected position. |
| **`R`** *(op/visual)* | **Treesitter search** — type a pattern, navigate to matching AST nodes. |
| **`<C-s>`** *(cmd)* | **Toggle flash** on top of an active `/` or `:` search. |

**Workflow tip:** You want to yank the string inside `print("hello")` into a variable.
1. `yiw` on the new variable name — it's now in `"`.
2. `ä` → labels appear → type label for `"hello"` → cursor teleports.
3. `ci"` → change inside quotes.

---

### `ö` — Orientation (structure navigation)
*Only active on Linux (treesitter not compiled on Windows).*

| Key | Direction | What |
| :--- | :--- | :--- |
| **`ön`** / **`öp`** | Next / Prev | Function |
| **`öc`** / **`öC`** | Next / Prev | Class |
| **`öl`** / **`öL`** | Next / Prev | Loop |
| **`öi`** / **`öI`** | Next / Prev | Conditional (`if`/`else`) |
| **`öf`** / **`öb`** | Next / Prev | Paragraph (`}` / `{`) |

Each jump is added to the jump list → `<C-o>` / `<C-i>` to go back and forward.

---

## 1. Flash — Precision Navigation

Flash turns any visible position into a one-key destination.

### How it works
1. Press **`ä`**.
2. Every word on screen gets a 1–2 character label.
3. Type those characters → cursor teleports.
4. In visual mode the selection extends. With an operator (`d`, `y`, `c`) it acts on the range.

### Flash + operators (the really powerful bit)

| Combo | Result |
| :--- | :--- |
| `yä<label>` | Yank from cursor to the flash target |
| `dä<label>` | Delete from cursor to the flash target |
| `cä<label>` | Change to the flash target |
| `r<label>` *(op-pending)* | Apply current operator *at* label without moving cursor |

### Flash + treesitter (`Ä`)
Labels AST nodes instead of words. Great for selecting a whole function body
with one keystroke: `vÄ` → type label → entire function is selected.

### `<C-s>` in command mode
While typing `/searchterm`, press `<C-s>` → flash labels appear over every match.
Type a label to jump directly to that match instead of cycling with `n`.

---

## 2. Surround — `nvim-surround`

Add, change, and delete surrounding pairs: `()` `[]` `{}` `""` `''` ` `` ` `<tags>`.

> **Timing note:** `yss` and `yS` require typing the second key within 500 ms (which-key delay).
> Type them briskly.

### Add a surrounding

| Key | Action | Example |
| :--- | :--- | :--- |
| `ys<motion><char>` | Surround motion with char | `ysiw"` → `word` → `"word"` |
| `yss<char>` | Surround whole line | `yss(` → `(the whole line)` |
| `yS<motion><char>` | Surround, content on its own line | `ySip{` → block in `{…}` |
| `ySS<char>` | Surround whole line, linewise | |

### Change a surrounding

| Key | Action | Example |
| :--- | :--- | :--- |
| `cs<old><new>` | Change surrounding | `cs"'` → `"hi"` → `'hi'` |
| `cs'(` | Change `'` to `(…)` | `'hi'` → `(hi)` |
| `cst"` | Change HTML tag to `"` | `<em>hi</em>` → `"hi"` |
| `cS<old><new>` | Change, content on its own line | |

### Delete a surrounding

| Key | Action | Example |
| :--- | :--- | :--- |
| `ds<char>` | Remove surrounding | `ds"` → `"word"` → `word` |
| `ds(` | Remove parens | `(foo)` → `foo` |
| `dsf` | Remove function call | `print(x)` → `x` |

> **`dsf` gotcha:** Inside `print(foo())`, cursor must be on `print` to remove the outer call.
> If you're inside `foo`, use `ä` to flash-jump to `print` first, then `dsf`.

### Visual mode

| Key | Action |
| :--- | :--- |
| `S<char>` | Surround selection |
| `gS<char>` | Surround selection, linewise |

**Full workflow example:** Wrap a multi-line block in a `try:` … `except` (Python-style):
1. `V` → select the lines.
2. `S{` → wrap in `{}` (then edit to fit your language).

---

## 3. Comments — `mini.comment`

Filetype-aware: `--` in Lua, `#` in Python, `//` in JS, `<!-- -->` in HTML, etc.
A space is always inserted after the token (`-- text`, not `--text`).

| Key | Mode | Action |
| :--- | :--- | :--- |
| `gcc` | Normal | Toggle comment on current line |
| `gc<motion>` | Normal | Toggle comment on lines covered by motion |
| `gc3j` | Normal | Comment this line + 3 below |
| `gcip` | Normal | Comment inner paragraph |
| `gc` | Visual | Toggle comment on selection |

**Uncomment:** Same keys. If the lines are commented, they become uncommented.

---

## 4. FZF-Lua — Fuzzy Finding

Default search root: `H:\dokument\` (Windows) / cwd (Linux).
On Windows: binary files (images, PDFs, Office docs) appear in the file list
but cannot be previewed as text — press `<Ctrl-o>` to open them with the system app.

### Pickers

| Key | Picker | Notes |
| :--- | :--- | :--- |
| **`<leader>p`** | **Files** | fd whitelist: documents, images, media, code. |
| **`<leader>f`** | **Live grep** | Searches only text-based files. Type to filter. |
| **`<leader>b`** | **Buffers** | Switch between open buffers. |
| **`<leader><leader>`** | **Resume** | Re-open last picker with same query. |
| **`<leader>7`** | **Grep word** | Grep the word under the cursor. |
| **`<leader>8`** *(visual)* | **Grep selection** | Grep the visually selected text. |
| **`<leader>r`** | **Registers** | Browse and paste from registers. |
| **`<leader>m`** | **Marks** | Jump to any mark. |
| **`<leader>k`** | **All keymaps** | Full-width description column (custom picker). |
| **`<leader>K`** | **Buffer keymaps** | Keymaps active only in the current buffer/plugin. |
| **`<leader>j`** | **Help tags** | Search `:help` topics. |
| **`<leader>s`** | **Spell suggest** | Pick a spelling correction for word under cursor. |
| **`<leader>gs`** | **Git status** | Browse changed files. |
| **`<leader>gc`** | **Git file commits** | History of commits touching the current file. |

### Inside any fzf picker

| Key | Action |
| :--- | :--- |
| `<Enter>` | Open selected file |
| `<Ctrl-o>` | Open with system default app (PDF, image, Office…) |
| `<Ctrl-c>` / `<Esc>` | Close picker |
| `<Tab>` | Multi-select (where supported) |
| `<Ctrl-/>` | Toggle preview pane |

### Workflow: find where a function is called
1. Cursor on the function name.
2. `<leader>7` → live grep results for that word.
3. `<Enter>` to jump to any result.
4. `<leader><leader>` to re-open the same search later.

---

## 5. Oil — File Manager

Oil shows the directory as a normal buffer. **Edit it like text, then `:w` to apply.**
Rename a file = edit its name on the line. Delete = delete the line. Create = add a line.

Open with **`-`** from any buffer → opens the parent directory of the current file in a float.

### Navigation

| Key | Action |
| :--- | :--- |
| `<CR>` | Open file / enter directory |
| `-` | Go up to parent directory |
| `_` | Jump to the current working directory |
| `` ` `` | `:cd` to the directory you're viewing |
| `~` | `:tcd` (tab-local cd) to the directory you're viewing |

### Preview

| Key | Action |
| :--- | :--- |
| `<C-p>` | Preview file in a split (text files only) |

Preview is restricted to text-based files. Images, PDFs, Office documents, audio,
video, and archives show a notification instead. Use `gx` to open those.
Preview updates live as you move the cursor when open.

### Open in splits / tabs

| Key | Action |
| :--- | :--- |
| `<C-s>` | Open in a vertical split |
| `<C-h>` | Open in a horizontal split |
| `<C-t>` | Open in a new tab |

### Utility

| Key | Action |
| :--- | :--- |
| `<C-l>` | Refresh the directory listing |
| `<C-c>` | Close the oil float |
| `gx` | Open the entry with the system default application |
| `g.` | Toggle hidden files on/off |
| `gs` | Change sort order (name / size / mtime…) |
| `g?` | Show all oil keymaps (built-in help) |

### Windows visibility rules
By default only these file types are visible:
- Documents: `txt md html pdf doc docx odt rtf xlsx xls pptx ppt csv xml`
- Google Drive stubs: `gdoc gsheet gslides gform`
- Images: `png jpg jpeg gif svg webp bmp ico tiff`
- Audio: `mp3 wav flac aac ogg wma m4a opus aiff`
- Video: `mp4 mkv avi mov wmv flv webm m4v mpg mpeg`
- Archives: `zip rar 7z`
- Code/config: `json yaml yml toml lua py js ts log ini cfg`

Press `g.` to reveal everything else (executables, drivers, system files, etc.).
The `DICOM` folder is always hidden regardless.

### Workflow: rename several files
1. `-` to open oil.
2. Edit file names directly in the buffer (use regular vim editing).
3. `:w` to apply all changes at once.

---

## 6. Window, Split & Tab Management

### Splits

| Key | Action |
| :--- | :--- |
| `<leader>sv` | Split vertically (side by side) |
| `<leader>sh` | Split horizontally (top / bottom) |
| `<leader>se` | Equalize all split sizes |
| `<leader>sx` | Close the current split |

### Move focus between splits

| Key | Action |
| :--- | :--- |
| `<M-Left>` | Focus left split |
| `<M-Right>` | Focus right split |
| `<M-Up>` | Focus split above |
| `<M-Down>` | Focus split below |

Also works from a terminal buffer inside Neovim.

### Raw split commands (built-in)

| Key | Action |
| :--- | :--- |
| `<C-w>v` | Vertical split |
| `<C-w>s` | Horizontal split |
| `<C-w>c` | Close current window |
| `<C-w>o` | Close all *other* windows (keep current) |
| `<C-w>q` | Quit current window |
| `<C-w>=` | Equalize sizes |
| `<C-w>\|` | Maximize width |
| `<C-w>_` | Maximize height |
| `<C-w>< >` | Decrease / increase width |
| `<C-w>+ -` | Increase / decrease height |
| `<C-w>J K H L` | Move window to bottom / top / left / right (also changes layout) |

### Tabs

| Key | Action |
| :--- | :--- |
| `<leader>to` | New tab |
| `<leader>tx` | Close tab |
| `<leader>tn` | Next tab |
| `<leader>tp` | Previous tab |
| `<leader>tf` | Open current buffer in its own new tab |

---

## 7. Clipboard — System Copy (`Alt-y`)

The built-in `y` yanks into Neovim's default register (not the OS clipboard).
`<M-y>` works identically but copies to the system clipboard (`+` register).

| Key | Mode | Action |
| :--- | :--- | :--- |
| `<M-y><motion>` | Normal | System-copy motion — e.g. `<M-y>iw` copies word |
| `<M-y><M-y>` | Normal | System-copy the whole line |
| `<M-Y>` | Normal | System-copy from cursor to end of line |
| `<M-y>` | Visual | System-copy the selection |

**Examples:**
- `<M-y>i"` — copy the string content inside quotes to clipboard.
- `<M-y>ip` — copy the inner paragraph to clipboard.
- `<M-y>af` — copy the entire surrounding function to clipboard (Linux/treesitter).

**Paste from clipboard in normal mode:** `"+p`
**Paste from clipboard in insert mode:** `<C-r>+`

---

## 8. Misc Editing

| Key | Action |
| :--- | :--- |
| `<leader>nh` | Clear search highlights (`:nohl`) |
| `<leader>+` | Increment number under cursor (`<C-a>`) |
| `<leader>-` | Decrement number under cursor (`<C-x>`) |
| `<leader>tr` | Toggle relative line numbers |
| `gx` | Open URL or file path under cursor with system app |
| `gx` *(visual)* | Open URL/path of visual selection |

---

## 9. Core Motions

### File-level

| Key | Action |
| :--- | :--- |
| `gg` / `G` | Start / end of file |
| `{line}G` | Jump to line number — e.g. `42G` |
| `<C-d>` / `<C-u>` | Scroll down / up half a page |
| `<C-f>` / `<C-b>` | Scroll down / up a full page |
| `zt` / `zz` / `zb` | Scroll view so cursor is at top / middle / bottom |
| `<C-o>` / `<C-i>` | Jump back / forward in the jump list |
| `g;` / `g,` | Jump to older / newer edit location |

### Line-level

| Key | Action |
| :--- | :--- |
| `^` / `g_` | First non-blank char (^ includes invisible chars, g_ doesn't) |
| `0` | Column 0 (absolute beginning of line) |
| `$` | End of line |
| `%` | Jump to matching bracket `()[]{}` |
| `f<char>` / `F<char>` | Find char forward / backward on line |
| `t<char>` / `T<char>` | Move to just before char forward / backward |
| `;` / `,` | Repeat `f`/`t` find forward / backward |

### Word-level

| Key | Action |
| :--- | :--- |
| `w` / `W` | Next word start (small: punctuation splits; big: whitespace splits) |
| `e` / `E` | Next word end |
| `b` / `B` | Previous word start |
| `*` / `#` | Search forward / backward for exact word under cursor |
| `g*` / `g#` | Same but matches partial words too |

### Screen-level (without scrolling)

| Key | Action |
| :--- | :--- |
| `H` / `M` / `L` | Move cursor to top / middle / bottom of visible screen |
| `gj` / `gk` | Move by visible wrapped line (not logical line) |
| `g0` / `g$` | Start / end of wrapped visible line |

---

## 10. Core Editing

### Entering insert mode

| Key | Action |
| :--- | :--- |
| `i` / `a` | Insert before / after cursor |
| `I` / `A` | Insert at start / end of line |
| `o` / `O` | New line below / above and insert |
| `s` | Delete char and insert (n/a — owned by surround; use `cl` instead) |
| `gi` | Return to last insert position and enter insert mode |

### Changing text

| Key | Action |
| :--- | :--- |
| `r<char>` | Replace single char |
| `R` | Replace mode (overtype) |
| `cw` / `ciw` | Change to end of word / change inner word |
| `ct(` | Change up to (not including) `(` |
| `cc` / `C` | Change whole line / change to end of line |
| `J` / `gJ` | Join line below with a space / without a space |
| `~` | Toggle case of char under cursor |
| `gUiw` / `guiw` | Uppercase / lowercase inner word |
| `gUip` / `guip` | Uppercase / lowercase inner paragraph |
| `>>`/ `<<` | Indent / de-indent current line |
| `>ip` / `<ip` | Indent / de-indent inner paragraph |

### Deleting text

| Key | Action |
| :--- | :--- |
| `x` | Delete char under cursor |
| `dd` / `D` | Delete line / delete to end of line |
| `diw` / `daw` | Delete inner word / delete a word (incl. space) |
| `di"` / `da"` | Delete inside / around `"` |
| `dt(` | Delete until `(` |
| `dip` | Delete inner paragraph |

### Yanking

| Key | Action |
| :--- | :--- |
| `yy` / `Y` | Yank line / yank to end of line |
| `yiw` / `yaw` | Yank inner / outer word |
| `yi"` / `ya"` | Yank inside / around quotes |
| `"0p` | Paste from register `0` (the last *yank*, unaffected by deletes) |

---

## 11. Treesitter Text Objects *(Linux only)*

*Use after any operator: `d`, `c`, `y`, `v`.*

Convention: `i` = **i**nner (content only), `a` = **a**round (incl. delimiters/keywords).

| Key | Text object | Examples |
| :--- | :--- | :--- |
| `if` / `af` | Function | `dif` delete body · `yaf` yank whole function |
| `ic` / `ac` | Class | `yic` yank class body · `vac` select whole class |
| `ia` / `aa` | Argument/parameter | `cia` change argument · `daa` delete with comma |
| `il` / `al` | Loop | `dal` delete whole loop · `vil` select loop body |
| `ii` / `ai` | Conditional (if/else) | `vii` select inside `if` · `dai` delete whole if block |

**Workflow:** Duplicate a function:
1. `yaf` → yank the whole function.
2. `ön` → jump to the next function.
3. `P` → paste above.

---

## 12. Macros & Registers

### Recording and playing

| Key | Action |
| :--- | :--- |
| `q<letter>` | Start recording macro into register `<letter>` |
| `q` | Stop recording |
| `@<letter>` | Play macro |
| `@@` | Replay last macro |
| `5@a` | Play macro `a` five times |
| `:g/pattern/normal @a` | Play macro `a` on every line matching pattern |

### Registers

| Register | Contains |
| :--- | :--- |
| `"` | Default (unnamed) register |
| `0` | Last yank (unaffected by deletes) — paste with `"0p` |
| `+` | System clipboard |
| `*` | Primary selection (Linux) |
| `a`–`z` | Named registers — use `"ayy` to yank into `a` |
| `A`–`Z` | Append to named register — `"Ayy` appends to `a` |
| `/` | Last search pattern |
| `:` | Last `:` command |
| `.` | Last inserted text |
| `%` | Current file name |

**In insert mode:** `<C-r><register>` pastes from any register.
**Examples:** `<C-r>0` paste last yank · `<C-r>/` paste last search · `<C-r>+` paste clipboard.

**Browse registers visually:** `<leader>r` → fzf register picker.

---

## 13. Visual Block Mode

*Enter with `<C-v>`.*

| Operation | Steps |
| :--- | :--- |
| **Prepend text to multiple lines** | `<C-v>` → select rows → `I` → type text → `<Esc>` |
| **Append text to multiple lines** | `<C-v>` → select rows → `$A` → type text → `<Esc>` |
| **Delete a column** | `<C-v>` → select column → `d` |
| **Replace a column** | `<C-v>` → select column → `r<char>` |
| **Increment a column of numbers** | `<C-v>` → select numbers → `g<C-a>` (sequential) or `<C-a>` (all +1) |
| **Indent a block** | `<C-v>` → select → `>` or `<` |

---

## 14. The `:s` Substitute Command

```
:[range]s/pattern/replacement/flags
```

| Flag | Meaning |
| :--- | :--- |
| `g` | Replace all matches on the line (not just the first) |
| `c` | Confirm each replacement interactively |
| `i` | Case-insensitive |
| `I` | Case-sensitive (override `ignorecase`) |

**Common patterns:**
```vim
:s/foo/bar/         " Replace first 'foo' on current line
:s/foo/bar/g        " Replace all 'foo' on current line
:%s/foo/bar/g       " Replace all 'foo' in the whole file
:%s/foo/bar/gc      " Replace all, confirm each one
:'<,'>s/foo/bar/g   " Replace in visual selection (auto-filled after V + :)
```

**`\zs` — zero-width start (positive lookbehind substitute):**
Replace `data` with `this_data` only when preceded by `(` or `=`, keeping the preceding char:
```vim
:%s/[(=]\zsdata/this_data/gc
```
Use `\v` (very magic) at the start of patterns to make them behave like Python regex:
```vim
:%s/\v(foo|bar)/baz/g
```

---

## 15. The `:g` Global Command

`:g` finds every line matching a pattern and runs a command on each.

```
:[range]g/pattern/command
```

| Example | Effect |
| :--- | :--- |
| `:g/error/d` | Delete every line containing "error" |
| `:g/TODO/m$` | Move all TODO lines to the end of the file |
| `:g/CHAPTER/p` | Print (show) all lines with "CHAPTER" |
| `:g/pattern/normal @a` | Run macro `a` on every matching line |
| `:g/ERROR/s/low/high/g` | On ERROR lines only, replace "low" with "high" |
| `:v/DEBUG/d` | Delete lines that do **not** match "DEBUG" (`:v` = inverse `:g`) |

`:v/pattern/command` is the inverse — runs the command on lines that do **not** match.

---

## 16. `g` Motion Reference

| Key | Action |
| :--- | :--- |
| `gd` | Go to local definition |
| `gD` | Go to global definition |
| `gf` | Open file whose name is under cursor |
| `gx` | Open URL / path under cursor in system app |
| `gv` | Re-select last visual selection |
| `gi` | Return to last insert position and re-enter insert |
| `g;` / `g,` | Jump to older / newer position in change list |
| `gj` / `gk` | Move down / up by visible wrapped line |
| `g0` / `g$` | Start / end of visible wrapped line |
| `gI` | Insert at column 0 (before any invisible chars) |
| `gg` / `G` | Start / end of file |
| `ga` | Show ASCII / Unicode value of char under cursor |
| `gU<motion>` | Uppercase — e.g. `gUiw` uppercases inner word |
| `gu<motion>` | Lowercase — e.g. `guip` lowercases paragraph |
| `g~<motion>` | Toggle case |
| `gJ` | Join line below without adding a space |
| `g<C-a>` | Increment column of numbers sequentially |
| `g*` / `g#` | Search forward / backward for word (partial match ok) |

---

## 17. Undo & History

| Key | Action |
| :--- | :--- |
| `u` | Undo last change |
| `U` | Undo all changes on current line |
| `<C-r>` | Redo |
| `5<C-r>` | Redo 5 times |
| `g-` / `g+` | Travel to older / newer branch of the undo tree |
| `:earlier 5m` | Roll back to state 5 minutes ago |
| `:later 30s` | Jump forward 30 seconds |
| `:undolist` | Show undo tree statistics |

---

## 18. Command Window & Search History

| Key | Mode | Action |
| :--- | :--- | :--- |
| `q:` | Normal | Open the command history as an editable buffer |
| `<C-f>` | Command | Same — open command history from inside `:` |
| `q/` | Normal | Open search history as an editable buffer |

In the command window: edit any previous command like normal text, then press `<Enter>` to execute it.

---

## 19. Regex Quick Reference

Use `\v` (very magic) to write patterns like Python:
```vim
/\v(foo|bar)+   " match foo or bar one or more times
```

| Pattern | Meaning |
| :--- | :--- |
| `\v` | Very magic — `+`, `\|`, `()` work without escaping |
| `\w` | Word character |
| `\s` | Whitespace |
| `\d` | Digit |
| `\<` / `\>` | Word boundary start / end |
| `\zs` | Zero-width start — "start the match HERE" (lookbehind substitute) |
| `\ze` | Zero-width end — "end the match HERE" |
| `\n` | Newline (in pattern) |
| `.` | Any char except newline |

**Confirm-replace workflow:** `:%s/pattern/replacement/gc` — `y` accept, `n` skip, `a` all, `q` quit.

---

## 20. Sorting & Filtering Lines

```vim
:%!sort              " Sort all lines alphabetically
:%!sort -r           " Sort in reverse
:%!sort -n           " Sort numerically
:'<,'>!sort          " Sort visual selection
:'<,'>!sort | uniq   " Sort and remove duplicates
:g/Priority: LOW/m$  " Move all 'Priority: LOW' lines to the bottom
:v/important/d       " Delete every line that doesn't contain 'important'
```

---

## 21. Combo Workflows

### Find and refactor a function name

1. `<leader>7` — grep word under cursor (the old name) → confirm all call sites.
2. `ä` → flash-jump to the function definition.
3. `ciw` → type the new name.
4. `<leader>7` again — verify no old occurrences remain.

### Explore an unfamiliar file quickly

1. `-` → open oil to see the directory layout.
2. `<leader>p` → find a file by partial name.
3. `<leader>f` → grep for a keyword to locate relevant code.
4. `ön` / `öp` (Linux) — navigate between functions within the file.
5. `[[ ` / `]]` — Neovim built-in: jump between top-level functions.

### Copy a value to clipboard and paste in another app

1. Position cursor on the value.
2. `<M-y>iw` — system-copy the inner word.
3. Switch to your other app → paste normally.

### Surround + flash combo

Goal: wrap the second argument of `foo(bar, baz)` in quotes.
1. `ä` → flash-jump to `baz`.
2. `ysiw"` → `baz` becomes `"baz"`.

### Multi-file rename with oil

1. `-` → open oil in the target directory.
2. Edit file names directly (use `cw`, `ciw`, etc.).
3. `:w` → all renames applied atomically.

---

*Search this file: `<leader>f` → type any keyword. Or open it with `-` and `<C-p>` to preview.*
