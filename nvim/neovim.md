# 🇸🇪 Neovim Master Reference: The "Kung Fu" Edition
*Current as of your `lazy-lock.json` and `lua/config/*` setup.*

**Leader Key:** Space (` `)

---

## 1. The Swedish Triad (Unique Config)

### `ä` = Attention (Flash & Navigation)
*Replaces default `s` to avoid conflict with nvim-surround.*
- **`ä`**: **Jump** to any word/char on screen[cite: 186].
- **`Ä`**: **Treesitter Select** (Highlight functions/classes/blocks)[cite: 186].
- **`dä`**: **Delete Remote** (Press `dä` -> Jump to word -> Delete it).
- **`yä`**: **Yank Remote** (Press `yä` -> Jump to word -> Copy it).
- **`cä`**: **Change Remote** (Press `cä` -> Jump to word -> Edit it).
- **`R`**: **Treesitter Search** (Search for "function" and jump to it)[cite: 187].

### `ö` = Orientation (Structure Movement)
*Replaces `{` and `}` for better ergonomics on Swedish layout.*
- **`ön` / `öp`**: Next / Prev **Function**[cite: 162].
- **`öc` / `öC`**: Next / Prev **Class**[cite: 162].
- **`öl` / `öL`**: Next / Prev **Loop**[cite: 162].
- **`öi` / `öI`**: Next / Prev **Conditional** (`if/else`)[cite: 163].
- **`öf` / `öb`**: Next / Prev **Paragraph**[cite: 163].

### `å` = Actions (Debugging)
*Requires `pip install debugpy` in your venv.*
- **`åc`**: Continue / Start[cite: 136].
- **`åb`**: Toggle Breakpoint[cite: 136].
- **`å1`**: Step Over[cite: 136].
- **`åi`**: Step Into[cite: 136].
- **`åu`**: Toggle Debug UI[cite: 137].
- **`åx`**: Stop/Terminate[cite: 137].
- **`åe`**: Evaluate Expression[cite: 139].
- **`åd[f/s/t]`**: Dump variable to **f**ile / **s**plit / **t**ab[cite: 144, 145, 147].

---

## 2. Core Editing & Motions

### The "Dank" Clipboard (System Copy)
- **`<Alt-y>`**: Copy motion to **System Clipboard** (e.g., `<A-y>iw`)[cite: 115].
- **`<Alt-y><Alt-y>`**: Copy **whole line** to System Clipboard[cite: 114].
- **`<Alt-Y>`**: Copy to **end of line** to System Clipboard[cite: 114].

### Standard Motions (Normal Mode)
- **`gg` / `G`**: Start / End of file.
- **`^` / `$`**: First non-empty char / End of line.
- **g_**: First non whitespace
- **`%`**: Go to matching bracket `()[]{}`.
- **`C-d` / `C-u`**: Scroll Down / Up half page.
- **`C-o` / `C-i`**: Jump Back / Forward (Jumplist).

### Editing
- **`A`**: Append to end of line.
- **`I`**: Insert at beginning of line.
- **`o` / `O`**: New line below / above.
- **`diw` / `yiw`**: Delete / Yank inside word.
- **`ciw`**: Change inside word.
- **`dt(`**: Delete until `(`.
- **`r`**: Replace single char.
- **`J`**: Join line below to current line.

---

## 3. Surround (`nvim-surround`)
*Mapped to `s` (Sandwich).*

- **`ysiw"`**: Surround inner word with `"`.
- **`ysaf)`**: Surround surrounding function with `)`.
- **`ds"`**: Delete surrounding `"`.
- **`dsf`**: Delete surrounding function call.
    * *Warning:* Inside `print(foo())`, `dsf` deletes `foo`.
    * *Fix:* Jump to the `print` keyword first (use `ä`), then `dsf`.
- **`cs"'`**: Change surrounding `"` to `'`.

---

## 4. Search & Files (FZF & Oil)

### FZF-Lua (Fuzzy Finding)
- [cite_start]**`<leader>p`**: Find Files[cite: 111].
- [cite_start]**`<leader>f`**: Live Grep (Text search)[cite: 111].
- [cite_start]**`<leader>b`**: Open Buffers[cite: 112].
- [cite_start]**`<Space> r <Space>`**: Registers[cite: 111].
    * *Note:* Requires extra Space or wait because `<leader>rn` (Rename) exists.
- [cite_start]**`<leader>7`**: Grep word under cursor[cite: 112].
- [cite_start]**`<leader><leader>`**: Resume last search[cite: 111].

### Oil (File Manager)
- [cite_start]**`-`**: Open Parent Directory (Float)[cite: 207].
- [cite_start]**`g.`**: Toggle hidden files[cite: 16].
- [cite_start]**`<leader>db`**: Add SQLite file to Dadbod UI (Custom)[cite: 16].

---

## 5. LSP & Coding Intelligence

### Navigation (Jedi/LSP)
- [cite_start]**`gd`**: Go to Definition (FZF)[cite: 164].
- [cite_start]**`gr`**: References (FZF)[cite: 164].
- [cite_start]**`K`**: Hover Documentation.
- [cite_start]**`<leader>rn`**: Rename Variable.
    * *Note:* This mapping causes the delay when trying to open Registers.
- [cite_start]**`<leader>ca`**: Code Actions[cite: 113].
- [cite_start]**`<leader>cd`**: Document Diagnostics[cite: 112].
- [cite_start]**`<leader>cs`**: Document Symbols[cite: 112].

### AI (Neocodeium)
- [cite_start]**`<Alt-l>`**: Accept suggestion[cite: 113].
- [cite_start]**`<Alt-j>` / `<Alt-k>`**: Cycle suggestions[cite: 113].
- [cite_start]**`<Alt-h>`**: Clear suggestion[cite: 113].

### Comments & Swap
- [cite_start]**`gcc`**: Toggle comment line[cite: 120].
- [cite_start]**`gc`**: Toggle comment selection (Visual)[cite: 120].
- [cite_start]**`cx`**: Swap items (select two args to swap)[cite: 82].

---

## 6. Window & Tab Management

### Windows (Splits)
- [cite_start]**`<leader>sv`**: Split Vertical[cite: 110].
- [cite_start]**`<leader>sh`** : Split Horizontal[cite: 110].
- [cite_start]**`<leader>se`**: Equalize split sizes[cite: 110].
- [cite_start]**`<leader>sx`**: Close split[cite: 110].
- [cite_start]**`<leader>tr`**: Toggle Relative Numbers[cite: 207].

### Tabs
- [cite_start]**`<leader>to`**: Open New Tab[cite: 110].
- [cite_start]**`<leader>tx`**: Close Tab[cite: 110].
- [cite_start]**`<leader>tn` / `tp`**: Next / Prev Tab[cite: 110, 111].
- [cite_start]**`<leader>tf`**: Move current buffer to new tab[cite: 111].

---

## 7. Treesitter Text Objects
*Use after `d`, `c`, `y`, or `v`.*

| Key | Object | Example |
| :--- | :--- | :--- |
| **`if` / `af`** | Function | [cite_start]`dif` (Delete inner func), `daf` (Delete all func)[cite: 157]. |
| **`ic` / `ac`** | Class | [cite_start]`yic` (Yank inner class)[cite: 157]. |
| **`ia` / `aa`** | Argument | [cite_start]`cia` (Change inner argument)[cite: 158]. |
| **`il` / `al`** | Loop | [cite_start]`dal` (Delete loop)[cite: 158]. |
| **`ii` / `ai`** | If/Conditional | [cite_start]`vii` (Select inside `if`)[cite: 159]. |

---

## 8. Macros & Registers
- **`qa`**: Record macro to register `a`.
- **`q`**: Stop recording.
- **`@a`**: Play macro `a`.
- **`@@`**: Replay last macro.
- **`<C-r>a`**: Paste register `a` while in **Insert Mode**.
- **`"0p`**: Paste from register 0 (the last *yank*, ignoring deletes).

---

## 9. Visual Block Mode Tricks
*Enter with `Ctrl-v`.*

1.  **Multi-Line Edit**: Select column → `Shift-I` → Type text → `Esc` (Applies to all).
2.  **Append to Lines**: Select column → `$` (End of line) → `Shift-A` → Type text → `Esc`.
3.  **Increment Numbers**: Select column of numbers → `g` `Ctrl-a`.
