-- =============================================================================
-- config/keymaps.lua  –  plugin-free keymaps
--
-- All descriptions use [tag] prefixes so <leader>k fuzzy search is useful:
--   [win]     window / split management
--   [tab]     tab management
--   [clip]    clipboard
--   [edit]    misc editing helpers
--   [oil]     file manager (open trigger; the rest live in plugins/oilfilemanager.lua)
-- =============================================================================

local km = vim.keymap

-- =============================================================================
-- File manager (oil)
-- =============================================================================
-- Press  -  from any buffer to open oil in the parent directory of the current file.
-- If the buffer has no associated file (e.g. a terminal or scratch buffer),
-- oil opens in the current working directory instead.
--
-- We call open_float(dir) explicitly rather than the default open() to avoid
-- a Windows bug in oil's posix_to_os_path where a nil drive letter crashes
-- when oil is opened from a pathless buffer.

km.set("n", "-", function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or dir == "." or not vim.fn.isdirectory(dir) then
    dir = vim.fn.getcwd()
  end
  require("oil").open_float(dir)
end, { desc = "[oil] open parent dir" })

-- =============================================================================
-- Misc editing
-- =============================================================================

km.set("n", "<leader>tr", ":ToggleRelativeNumber<CR>", { silent = true, desc = "[edit] toggle relative numbers" })
km.set("n", "<leader>tl", ":ToggleX0b<CR>",           { silent = true, desc = "[edit] toggle x0b line-break convert" })
km.set("n", "<leader>nh", ":nohl<CR>",                 { desc = "[edit] clear search highlights" })
km.set({ "n", "x" }, "<leader>+",  "<C-a>",  { desc = "[edit] increment number(s)" })
km.set({ "n", "x" }, "<leader>-",  "<C-x>",  { desc = "[edit] decrement number(s)" })
-- g<leader>+/- → sequential increment/decrement for visual block columns
-- (<C-a>/<C-x> are eaten by tmux; these route around it)
km.set("x", "g<leader>+", "g<C-a>", { desc = "[edit] sequential increment (visual)" })
km.set("x", "g<leader>-", "g<C-x>", { desc = "[edit] sequential decrement (visual)" })

-- =============================================================================
-- Ö: append-and-stay
-- =============================================================================
-- Waits for one character, appends it immediately after the character under
-- the cursor, then restores the cursor to its original position.
--
--   Ö<Space>  → inserts a space after the current char; cursor stays put
--   Ö<Enter>  → splits the line after the current char;  cursor stays put
--   Ö<Esc>    → abort, no change

km.set("n", "Ö", function()
  local char = vim.fn.getcharstr()
  if char == "\27" then return end              -- ESC → abort
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if char == "\r" or char == "\n" then
    -- Split line: keep up-to-and-including the cursor char here, rest on a new line
    vim.api.nvim_set_current_line(line:sub(1, col + 1))
    vim.api.nvim_buf_set_lines(0, row, row, false, { line:sub(col + 2) })
  else
    vim.api.nvim_set_current_line(line:sub(1, col + 1) .. char .. line:sub(col + 2))
  end
  vim.api.nvim_win_set_cursor(0, { row, col })
end, { desc = "[edit] Ö: append char after cursor, return to position" })

-- gx: open URL or file path under the cursor with the system default application.
-- Override built-in gx just to attach the [edit] description tag.
km.set("n", "gx", function() vim.ui.open(vim.fn.expand("<cfile>")) end, { desc = "[edit] open URL/path under cursor" })
km.set("x", "gx", function() vim.ui.open(vim.fn.expand("<cfile>")) end, { desc = "[edit] open URL/path (visual)" })

-- =============================================================================
-- Window / split management
-- =============================================================================
-- Use Alt-Arrow keys to move focus between splits without leaving home row.

km.set("n", "<leader>sv", "<C-w>v",         { desc = "[win] split vertical" })
km.set("n", "<leader>sh", "<C-w>s",         { desc = "[win] split horizontal" })
km.set("n", "<leader>se", "<C-w>=",         { desc = "[win] equal splits" })
km.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "[win] close split" })

km.set("n", "<M-Left>",  "<C-w>h", { desc = "[win] go left" })
km.set("n", "<M-Down>",  "<C-w>j", { desc = "[win] go down" })
km.set("n", "<M-Up>",    "<C-w>k", { desc = "[win] go up" })
km.set("n", "<M-Right>", "<C-w>l", { desc = "[win] go right" })

-- =============================================================================
-- Tab management
-- =============================================================================

km.set("n", "<leader>to", function() vim.cmd("tabnew") end,   { desc = "[tab] new" })
km.set("n", "<leader>tx", function() vim.cmd("tabclose") end, { desc = "[tab] close" })
km.set("n", "<leader>tn", "<cmd>tabn<CR>",                    { desc = "[tab] next" })
km.set("n", "<leader>tp", "<cmd>tabp<CR>",                    { desc = "[tab] prev" })
km.set("n", "<leader>tf", "<cmd>tabnew %<CR>",                { desc = "[tab] buf in new tab" })

-- =============================================================================
-- Clipboard (system register)
-- =============================================================================
-- Alt-y works as a "system yank" operator — same idea as y but copies to the
-- OS clipboard (+) instead of Neovim's default register.
--
--   <M-y> + motion   System-yank the text covered by the motion.
--                    Example:  <M-y>iw  → copy word to clipboard
--                              <M-y>3j  → copy 3 lines to clipboard
--   <M-y><M-y>       System-yank the whole line  (operator-pending "_" trick)
--   <M-Y>            System-yank from cursor to end of line  (mirrors Y)
--   <M-y> (visual)   System-yank the selection

km.set({ "n", "x" }, "<M-y>", '"+y',  { desc = "[clip] system copy" })
km.set("o",          "<M-y>", "_",    { desc = "[clip] system copy line motion" })
km.set("n",          "<M-Y>", '"+y$', { desc = "[clip] system copy to EOL" })

-- =============================================================================
-- Windows fallbacks: fzf-lua pickers (fzf-lua disabled on Windows)
-- =============================================================================
-- fzf-lua is disabled on Windows (no fzf/rg/fd binaries; Defender cost).
-- These replacements use scratch buffers or built-in commands.
-- <leader>p/f/7/8/<leader>/gs/gc are intentionally left unmapped — not needed
-- for the paste-edit-copy workflow.

if vim.g.is_windows then

  -- ── <leader>k / <leader>K : keymap browser ─────────────────────────────────
  -- Scratch buffer listing all keymaps. Search with /, close with q.

  local function win_show_keymaps(buf_only)
    local entries = {}
    local seen    = {}
    local modes   = { "n", "i", "v", "x", "o", "c", "t", "s" }

    local function collect(maps, prefix)
      for _, map in ipairs(maps) do
        local lhs = (map.lhs or ""):gsub(" ", "<Space>")
        if not lhs:find("^<Plug>", 1, true) then
          local desc = map.desc or (type(map.rhs) == "string" and map.rhs) or ""
          if desc ~= "" then
            local key = map.mode .. "\0" .. lhs
            if not seen[key] then
              seen[key] = true
              table.insert(entries, string.format("%-3s  %-20s  %s%s", map.mode, lhs, prefix, desc))
            end
          end
        end
      end
    end

    for _, mode in ipairs(modes) do
      if not buf_only then
        collect(vim.api.nvim_get_keymap(mode), "")
      end
      collect(vim.api.nvim_buf_get_keymap(0, mode), buf_only and "" or "[buf] ")
    end

    table.sort(entries)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, entries)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden  = "wipe"
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, math.min(#entries, 25))
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
  end

  km.set("n", "<leader>k", function() win_show_keymaps(false) end, { desc = "[edit] keymaps all" })
  km.set("n", "<leader>K", function() win_show_keymaps(true)  end, { desc = "[edit] keymaps this buffer" })

  -- ── <leader>b : buffer list ────────────────────────────────────────────────
  -- Scratch buffer listing open buffers. <CR> to switch, q to close.

  km.set("n", "<leader>b", function()
    local bufnrs  = {}
    local entries = {}
    local current = vim.api.nvim_get_current_buf()

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
        local name  = vim.api.nvim_buf_get_name(bufnr)
        local short = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
        local flag  = bufnr == current and "%" or " "
        local mod   = vim.bo[bufnr].modified and " [+]" or ""
        table.insert(entries, string.format(" %s %3d  %s%s", flag, bufnr, short, mod))
        table.insert(bufnrs, bufnr)
      end
    end

    if #entries == 0 then vim.notify("No listed buffers") return end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, entries)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden  = "wipe"
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, math.min(#entries + 1, 15))

    vim.keymap.set("n", "<CR>", function()
      local line   = vim.api.nvim_win_get_cursor(0)[1]
      local target = bufnrs[line]
      vim.cmd("close")
      vim.api.nvim_set_current_buf(target)
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
  end, { desc = "[edit] buffers" })

  -- ── <leader>r : registers ──────────────────────────────────────────────────
  km.set("n", "<leader>r", ":registers<CR>", { desc = "[edit] registers" })

  -- ── <leader>m : marks ─────────────────────────────────────────────────────
  km.set("n", "<leader>m", ":marks<CR>", { desc = "[edit] marks" })

  -- ── <leader>s : spell suggest ─────────────────────────────────────────────
  -- z= opens Neovim's numbered suggestion list. Type a number + <CR> to apply.
  km.set("n", "<leader>s", "z=", { desc = "[edit] spell suggest" })

  -- ── <leader>j : help ──────────────────────────────────────────────────────
  -- Pre-fills :help in the command line. Type a topic or use <Tab> to complete.
  km.set("n", "<leader>j", ":help ", { desc = "[edit] help" })

end

-- =============================================================================
-- Linux-only keymaps (plugins disabled on Windows)
-- =============================================================================

if not vim.g.is_windows then

  -- ── Neocodeium: AI completion ───────────────────────────────────────────────
  -- neocodeium loads on VeryLazy; use function wrappers so require is deferred.
  --
  --   <A-l>   Accept full suggestion
  --   <A-j>   Next suggestion
  --   <A-k>   Previous suggestion
  --   <A-h>   Clear suggestion
  --   <A-c>   Cycle or complete
  --   <A-ö>   Accept next word  (Swedish layout convenience alias)
  --   <A-o>   Accept next word
  --   <A-p>   Accept next line

  km.set("i", "<A-l>", function() require("neocodeium").accept()             end, { desc = "[ai] accept suggestion" })
  km.set("i", "<A-j>", function() require("neocodeium").cycle_or_complete()  end, { desc = "[ai] next suggestion" })
  km.set("i", "<A-k>", function() require("neocodeium").cycle_or_complete(-1) end, { desc = "[ai] prev suggestion" })
  km.set("i", "<A-h>", function() require("neocodeium").clear()              end, { desc = "[ai] clear suggestion" })
  km.set("i", "<A-c>", function() require("neocodeium").cycle_or_complete()  end, { desc = "[ai] cycle or complete" })
  km.set("i", "<A-ö>", function() require("neocodeium").accept_word()        end, { desc = "[ai] accept word" })
  km.set("i", "<A-o>", function() require("neocodeium").accept_word()        end, { desc = "[ai] accept word" })
  km.set("i", "<A-p>", function() require("neocodeium").accept_line()        end, { desc = "[ai] accept line" })

  -- ── LSP (fzf-lua backed) ────────────────────────────────────────────────────
  -- gd / gr / K / <leader>rn are buffer-local at LspAttach in lsp-jedi.lua.
  -- These are global extras that also use fzf-lua.

  km.set("n", "<leader>cj", function() require("fzf-lua").lsp_definitions()  end, { desc = "[lsp] jump to definition" })
  km.set("n", "<leader>cr", function() require("fzf-lua").lsp_references()   end, { desc = "[lsp] references" })
  km.set("n", "<leader>ca", function()
    require("fzf-lua").lsp_code_actions({
      winopts = { relative = "cursor", row = 1.01, col = 0, height = 0.2, width = 0.4 },
    })
  end, { desc = "[lsp] code actions" })
  km.set("n", "<leader>cd", function()
    require("fzf-lua").diagnostics_document({ fzf_opts = { ["--wrap"] = true } })
  end, { desc = "[lsp] document diagnostics" })
  km.set("n", "<leader>cs", function()
    require("fzf-lua").lsp_document_symbols({ winopts = { preview = { wrap = "wrap" } } })
  end, { desc = "[lsp] document symbols" })
  km.set("n", "<leader>cp", function()
    require("fzf-lua").lsp_definitions({
      jump1   = false,
      winopts = { preview = { layout = "vertical", vertical = "up:60%" } },
    })
  end, { desc = "[lsp] peek definition" })

  -- ── FTmux: run current file / project in tmux ───────────────────────────────
  km.set("n", "<leader>RT", "<cmd>FTmuxRun<CR>",                      { desc = "[tmux] run this file" })
  km.set("n", "<leader>RM", "<cmd>FTmuxRunRoot<CR>",                   { desc = "[tmux] run root main.py" })
  km.set("n", "<leader>RA", "<cmd>FTmuxRunRoot /interface/app.py<CR>", { desc = "[tmux] run root app.py" })

end
