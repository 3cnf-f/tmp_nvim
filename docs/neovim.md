# 🇸🇪 Neovim Master Reference: The "Kung Fu" Edition
*Current as of your `lazy-lock.json` and `lua/config/*` setup.*

**Leader Key:** Space (` `)

---
## 0. Navigation
- **`alt-arrow`**: Navigate between windows(works from REPL terminal as well).

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

#### **`å` = Actions (Debugger / DAP)**
*Strictly for controlling the execution flow when debugging.*
- **`åc`**: **Continue** / Start Debugging.
- **`åb`**: **Breakpoint** (Toggle).
- **`åB`**: **Conditional Breakpoint** (Ask for condition).
- **`åi` / `åo`**: Step **Into** / Step **Out**.
- **`å1`**: Step **Over**.
- **`år`**: Open **Debug Console** (Internal DAP REPL, *not* Iron).
- **`åu`**: Toggle **Debug UI**.
- **`åe`**: **Evaluate** expression.
- **`ådf` / `åds`**: Dump variable to **F**ile / **S**plit.

### `å` vs `Å`: The Precision Split
*We have separated "Debugging" from "Interactive Coding" to prevent accidents.*

#### **`Å` = Alchemist (Interactive REPL / Iron)**
*Shift + `å`. For dynamic code execution (Jupyter-style).*

**Management**
- **`Åt`**: **Toggle REPL** (Open/Close side window).
- **`År`**: **Restart Kernel** (Kill Python & start fresh).
- **`Åf`**: **Focus REPL** (Jump to it).
- **`Åh`**: **Hide REPL** (Keep running, but close split).
- **`Åc`**: **Clear Screen**.

**Sending Code ("The Mix")**
- **`Åss`**: Send **Current Line**.
- **`Åsf`**: Send **Whole File**.
- **`Åsb`**: Send **Block** (Visually selects paragraph & sends).
- **`Ås` + motion**: The Operator.
    - *Example:* `Åsip` → Send Inner Paragraph.
    - *Example:* `Åsaf` → Send Function.
    - *Example:* `Ås$` → Send to end of line.
- **`Ås` (Visual)**: Send currently selected text.
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


## [NEW] 11. The Tmux Runner (Heavy Lifting)
*Offloads execution to a dedicated pane (`test_pane`) to keep the editor fluid.*

**Setup**
1. Press `ö` in **Tmux** (not Vim) to generate the 4-pane IDE layout.
2. Ensure you are in the `editor_pane`.

**Commands**
- **`<leader>RT`**: **Run This File**.
    - *Action:* Zooms `test_pane` → Runs `python current_file.py` → Waits for Enter → Zooms back.
- **`<leader>RM`**: **Run Root Main**.
    - *Action:* Runs `python /git_root/main.py`.
- **`<leader>RA`**: **Run Root App**.
    - *Action:* Runs `python /git_root/interface/app.py`.

---

### [Examples] The "Combo" Workflow

**Scenario: Fixing a Bug in a Function**

1.  **Navigate:** Use `ön` (Next Function) to find the buggy function.
2.  **Test Interactive:**
    *   Open REPL: `Åt`.
    *   Send function to REPL: `Åsaf` (Send Around Function).
    *   Go to REPL: `Åf`.
    *   Test it manually.
    *   Jump back: `Alt-Left`.
3.  **Debug Deeply:**
    *   Set Breakpoint: `åb`.
    *   Run Debugger: `åc`.
    *   Step through: `å1` (Over), `åi` (Into).
    *   Inspect var: `åh` (Hover).
4.  **Run Full Test:**
    *   Run the file in Tmux Runner: `<leader>RT`.
