-- fzf-lua: fast fuzzy finder powered by fzf, ripgrep, and fd.
--
-- On Windows: fzf.exe and rg.exe must be placed in H:\007git\bin\
--   fzf.exe  → https://github.com/junegunn/fzf/releases        (windows_amd64.zip)
--   rg.exe   → https://github.com/BurntSushi/ripgrep/releases  (windows-msvc.zip)
--
-- Keymaps (all tagged [fzf] for <leader>k search)
-- ------------------------------------------------
--   <leader>p          Files: fuzzy-find files under H:\dokument\ (or cwd on Linux).
--                      <CR> opens.  <Ctrl-o> opens with system default app (for PDFs etc).
--   <leader>f          Live grep: search file contents while you type.
--   <leader><leader>   Resume last fzf picker (re-open with previous query).
--   <leader>b          Buffers: switch between open buffers.
--   <leader>r          Registers: pick a register to paste from.
--   <leader>m          Marks: jump to a mark.
--   <leader>k          All keymaps (custom picker — description gets full width).
--   <leader>K          Buffer-local keymaps for the current buffer / plugin context.
--   <leader>j          Help tags: search :help topics.
--   <leader>s          Spell suggest: pick a spelling correction for word under cursor.
--   <leader>gs         Git status: browse changed files.
--   <leader>gc         Git commits for the current file (bcommits).
--   <leader>8 (visual) Grep the visual selection.
--   <leader>7          Grep the word under the cursor.

-- On Windows: fzf-lua is skipped entirely. fzf.exe / rg.exe / fd.exe are
-- external binaries that trigger Windows Defender scans on every invocation,
-- which makes the picker unusably slow. For the paste-edit-copy workflow the
-- file/grep pickers are not needed anyway.
if vim.g.is_windows then return {} end

local is_win = vim.g.is_windows

-- =============================================================================
-- Custom keymaps picker
-- =============================================================================
-- fzf-lua's built-in keymaps picker has a fixed narrow column for the description
-- which cuts off most of our [tag] descriptions. This replacement formats each
-- entry as:  MODE   KEYMAP               DESCRIPTION
-- giving the description all remaining width.

local function show_keymaps(buf_only)
  local entries = {}
  local seen    = {}  -- deduplicate by "mode\0lhs"
  local modes   = { "n", "i", "v", "x", "o", "c", "t", "s" }

  local function collect(maps, prefix)
    for _, km in ipairs(maps) do
      local lhs = (km.lhs or ""):gsub(" ", "<Space>")
      -- Skip internal <Plug> targets — users never type these directly
      if lhs:find("^<Plug>", 1, true) then goto skip end
      local desc = km.desc or (type(km.rhs) == "string" and km.rhs) or ""
      if desc == "" then goto skip end
      -- Deduplicate: if this (mode, lhs) was already added, skip
      local key = km.mode .. "\0" .. lhs
      if seen[key] then goto skip end
      seen[key] = true
      table.insert(entries, string.format("%-3s  %-20s  %s%s", km.mode, lhs, prefix, desc))
      ::skip::
    end
  end

  for _, mode in ipairs(modes) do
    if not buf_only then
      collect(vim.api.nvim_get_keymap(mode), "")
    end
    -- Buffer-local keymaps are tagged [buf] when showing all keymaps,
    -- so you can distinguish plugin-context bindings from global ones.
    collect(vim.api.nvim_buf_get_keymap(0, mode), buf_only and "" or "[buf] ")
  end

  table.sort(entries)

  require("fzf-lua").fzf_exec(entries, {
    prompt  = buf_only and "Buffer Keymaps> " or "All Keymaps> ",
    winopts = {
      width  = 0.97,
      height = 0.85,
      preview = { layout = "vertical", vertical = "down:30%", hidden = "hidden" },
    },
  })
end

-- =============================================================================
-- Windows-only: file-listing and grep filtering
-- =============================================================================
-- On Windows we use whitelists to keep fzf fast and safe:
--   1. fd only lists files whose extension is on doc_exts (no executables, drivers…).
--   2. rg only greps inside text-based files (no binary content bleeding into results).
--   3. Binary files in the fzf preview pane show a message instead of raw bytes.
--   4. Several system folders are excluded entirely.
--
-- Performance notes (Windows Defender AV compatibility):
--   --no-mmap  : rg normally memory-maps files for speed; each mapped page triggers
--                an AV scan, which is extremely slow on a managed work machine.
--                Disabling mmap keeps rg reading sequentially — slower in theory
--                but much faster in practice because AV only scans each file once.
--   --threads 2: fewer parallel rg workers → fewer simultaneous AV hits.
--   --path-separator /: fd outputs forward slashes consistently, avoiding mixed
--                backslash/forward-slash paths that confuse Neovim's stat calls.
--   exec_empty_query = false: rg is not launched at all until you start typing,
--                preventing an expensive full-tree scan on picker open.

local win_fd_opts, win_rg_opts, win_binary_previewer

if is_win then
  -- Extensions that cannot be previewed as text — show a placeholder instead.
  -- fzf-lua's builtin previewer replaces the normal file display with this command.
  local binary_exts = {
    "pdf",
    "doc", "docx", "docm", "dotx", "dotm", "odt", "rtf",
    "xlsx", "xls", "xlsm", "xlsb", "ods",
    "pptx", "ppt", "pptm", "ppsx", "pps", "odp",
    "gdoc", "gsheet", "gslides", "gform",
    "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp", "ico", "tiff",
    "mp3", "wav", "flac", "aac", "ogg", "wma", "m4a", "opus", "aiff",
    "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v", "mpg", "mpeg",
    "zip", "rar", "7z",
  }
  win_binary_previewer = {}
  for _, ext in ipairs(binary_exts) do
    -- Tell the user what to do instead of showing garbage bytes
    win_binary_previewer[ext] = { "cmd", "/c", "echo", "[binary - Ctrl-o to open with default app]" }
  end

  -- fd extension whitelist: only files the user actually cares about.
  -- Executables, drivers, system files, temp files, etc. are excluded.
  local doc_exts = {
    -- Text / documents
    "txt", "md", "markdown", "html", "htm", "pdf",
    "doc", "docx", "docm", "dotx", "dotm", "odt", "rtf",
    "xml", "csv", "xlsx", "xls", "xlsm", "xlsb", "ods",
    "pptx", "ppt", "pptm", "ppsx", "pps", "odp",
    -- Google Drive desktop-sync stubs
    "gdoc", "gsheet", "gslides", "gform",
    -- Images
    "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp", "ico", "tiff",
    -- Audio
    "mp3", "wav", "flac", "aac", "ogg", "wma", "m4a", "opus", "aiff",
    -- Video
    "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v", "mpg", "mpeg",
    -- Archives
    "zip", "rar", "7z",
    -- Config / code
    "json", "yaml", "yml", "toml",
    "lua", "py", "js", "ts",
    -- Misc
    "log", "ini", "cfg",
  }

  -- Build  --extension txt --extension md …  flags for fd
  local fd_ext_flags = ""
  for _, ext in ipairs(doc_exts) do
    fd_ext_flags = fd_ext_flags .. " --extension " .. ext
  end

  win_fd_opts = table.concat({
    "--color=never --type f --path-separator /",  -- forward slashes avoid mixed-slash stat errors
    fd_ext_flags,
    "--exclude '$RECYCLE.BIN'",
    "--exclude 'System Volume Information'",
    "--exclude 'RecycleBin'",
    "--exclude 'DICOM'",
  }, " ")

  -- rg glob whitelist: grep only inside text-based files.
  -- Binary file types are intentionally absent — not playing sysadmin.
  win_rg_opts = table.concat({
    "--column --line-number --no-heading --color=always --smart-case",
    "--no-mmap --threads 2",  -- AV-friendly: no memory-mapped I/O, fewer parallel scans
    "--glob '*.{txt,md,html,htm,xml,csv,json,yaml,yml,toml,lua,py,js,ts,log,ini,cfg}'",
    "--glob '!$RECYCLE.BIN'",
    "--glob '!System Volume Information'",
    "--glob '!RecycleBin'",
    "--glob '!**/DICOM/**'",
  }, " ")
end

-- =============================================================================
-- Plugin spec
-- =============================================================================

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    -- Default search root. On Linux nil = cwd (standard behaviour).
    cwd     = is_win and "H:\\dokument\\" or nil,
    -- Explicit binary paths on Windows (not in system PATH by default)
    fzf_bin = is_win and "H:\\007git\\bin\\fzf.exe" or nil,

    files = {
      fd_opts = win_fd_opts,  -- nil on Linux → fzf-lua uses its own defaults
      actions = {
        -- <Ctrl-o> opens selected files with the system default app.
        -- Useful for PDFs, images, and Office files that cannot be edited in Neovim.
        ["ctrl-o"] = function(selected, opts)
          for _, sel in ipairs(selected) do
            local file = require("fzf-lua").path.entry_to_file(sel, opts)
            vim.ui.open(file.path)
          end
        end,
      },
    },

    grep = {
      rg_opts          = win_rg_opts,  -- nil on Linux → fzf-lua uses its own defaults
      cmd              = is_win and "H:\\007git\\bin\\rg.exe" or nil,
      exec_empty_query = false,  -- don't fire rg until you start typing (avoids full-tree scan)
    },

    previewers = {
      -- Replace binary file previews with a friendly message (Windows only).
      -- On Linux nil → fzf-lua uses bat/cat/highlight as available.
      builtin = { extensions = win_binary_previewer },
    },
  },

  -- -------------------------------------------------------------------------
  -- Keymaps
  -- -------------------------------------------------------------------------
  keys = {
    -- File / buffer navigation
    { "<leader>p",        function() require("fzf-lua").files()         end, desc = "[fzf] files" },
    { "<leader><leader>", function() require("fzf-lua").resume()        end, desc = "[fzf] resume last" },
    { "<leader>b",        function() require("fzf-lua").buffers()       end, desc = "[fzf] buffers" },
    -- Grep (live as you type / word / selection)
    { "<leader>f",        function() require("fzf-lua").live_grep()     end, desc = "[fzf] grep" },
    { "<leader>7",        function() require("fzf-lua").grep_cword()    end, desc = "[fzf] grep word" },
    { "<leader>8", mode = "v", function() require("fzf-lua").grep_visual() end, desc = "[fzf] grep selection" },
    -- Vim state
    { "<leader>r",        function() require("fzf-lua").registers()     end, desc = "[fzf] registers" },
    { "<leader>m",        function() require("fzf-lua").marks()         end, desc = "[fzf] marks" },
    -- Keymaps (custom picker with full-width description)
    { "<leader>k",        function() show_keymaps(false)                end, desc = "[fzf] keymaps all" },
    { "<leader>K",        function() show_keymaps(true)                 end, desc = "[fzf] keymaps this buffer" },
    -- Help / spelling
    { "<leader>j",        function() require("fzf-lua").helptags()      end, desc = "[fzf] help tags" },
    { "<leader>s",        function() require("fzf-lua").spell_suggest() end, desc = "[fzf] spelling" },
    -- Git
    { "<leader>gs",       function() require("fzf-lua").git_status()    end, desc = "[fzf] git status" },
    { "<leader>gc",       function() require("fzf-lua").git_bcommits()  end, desc = "[fzf] git file commits" },
  },
}
