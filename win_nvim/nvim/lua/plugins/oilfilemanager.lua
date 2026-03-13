-- Oil: edit the filesystem like a Neovim buffer.
--
-- Open with  -  from any buffer (see keymaps.lua → [oil] open parent dir).
-- The directory listing appears in a floating window. You can:
--   • Rename files/dirs by editing their names in the buffer, then :w to apply.
--   • Delete entries by deleting lines, then :w.
--   • Create files/dirs by adding new lines, then :w.
--   • Move files by cutting a line from one oil buffer and pasting in another.
--
-- NAVIGATION
--   <CR>   Open the file/dir under the cursor.
--   -      Go up to the parent directory (also opens oil from a normal buffer).
--   _      Jump to the current working directory.
--
-- PREVIEW
--   <C-p>  Preview the file under the cursor in a split (text files only).
--          Binary files (images, office docs, audio/video, archives) are blocked
--          from the preview buffer and show a notification instead.
--          Use  gx  to open those with the system default application.
--
-- SPLITS / TABS
--   <C-s>  Open in a vertical split.
--   <C-h>  Open in a horizontal split.
--   <C-t>  Open in a new tab.
--
-- UTILITY
--   <C-l>  Refresh the directory listing.
--   <C-c>  Close the oil float.
--   gx     Open the entry with the system default application (PDF, image, etc.).
--   g.     Toggle hidden files on/off.
--   gs     Change sort order.
--   `      :cd to the current directory.
--   ~      :tcd to the current directory (tab-local).
--   g?     Show all oil keymaps (built-in help).
--
-- WINDOWS vs LINUX
--   On Windows only document, image, media, code, and archive files are shown
--   by default. Everything else (exe, dll, sys, tmp, log …) is hidden and only
--   appears after pressing  g.  (toggle_hidden). On Linux all files show normally.
--
--   The DICOM folder (medical imaging data) is always hidden on Windows regardless
--   of the toggle, because it contains thousands of tiny files.

-- =============================================================================
-- Text-previewable extensions (safe to load into a Neovim buffer)
-- =============================================================================
-- Binary files (images, PDFs, office docs …) would render as garbage or crash
-- the preview. Only extensions listed here are allowed into the preview pane.

local previewable_exts = {
  txt=1, md=1, markdown=1,
  html=1, htm=1, xml=1, svg=1,   -- markup (svg is xml)
  csv=1, tsv=1,
  json=1, yaml=1, yml=1, toml=1,
  lua=1, py=1, js=1, ts=1,
  log=1, ini=1, cfg=1,
}

-- =============================================================================
-- safe_preview(): C-p handler — preview text files, block everything else
-- =============================================================================
-- Oil's built-in preview has no extension filter. This wrapper checks the
-- extension first and either delegates to the real preview or shows a notification
-- telling the user to use gx instead.

local function safe_preview()
  local entry = require("oil").get_cursor_entry()
  if not entry or entry.type ~= "file" then
    -- On a directory or unknown entry, just pass through to oil
    require("oil.actions").preview()
    return
  end
  local ext = entry.name:match("%.([^%.]+)$")
  if ext and previewable_exts[ext:lower()] then
    require("oil.actions").preview()
  else
    vim.notify(
      "No preview: " .. entry.name .. "  (gx = open with default app)",
      vim.log.levels.INFO
    )
  end
end

-- =============================================================================
-- is_hidden_file(): Windows-only whitelist for the directory listing
-- =============================================================================
-- On Windows we restrict the oil listing to "harmless user files" so the view
-- isn't cluttered with system binaries, driver files, and other noise.
-- Files not on the whitelist are treated as hidden — press  g.  to reveal them.

local is_hidden_file
if vim.g.is_windows then
  local visible_exts = {
    -- Text / documents
    txt=1, md=1, markdown=1, html=1, htm=1, pdf=1,
    doc=1, docx=1, docm=1, dotx=1, dotm=1, odt=1, rtf=1,
    xml=1, csv=1, xlsx=1, xls=1, xlsm=1, xlsb=1, ods=1,
    pptx=1, ppt=1, pptm=1, ppsx=1, pps=1, odp=1,
    -- Google Drive desktop-sync stubs (open in browser via gx)
    gdoc=1, gsheet=1, gslides=1, gform=1,
    -- Images
    png=1, jpg=1, jpeg=1, gif=1, svg=1, webp=1, bmp=1, ico=1, tiff=1,
    -- Audio
    mp3=1, wav=1, flac=1, aac=1, ogg=1, wma=1, m4a=1, opus=1, aiff=1,
    -- Video
    mp4=1, mkv=1, avi=1, mov=1, wmv=1, flv=1, webm=1, m4v=1, mpg=1, mpeg=1,
    -- Archives
    zip=1, rar=1, ["7z"]=1,
    -- Config / code
    json=1, yaml=1, yml=1, toml=1,
    lua=1, py=1, js=1, ts=1,
    -- Misc
    log=1, ini=1, cfg=1,
  }

  is_hidden_file = function(name, bufnr)
    -- Always hide the DICOM folder — it holds thousands of medical image files
    if bufnr then
      local dir = vim.api.nvim_buf_get_name(bufnr)
      if dir:lower():find("[/\\]dicom[/\\]") then return true end
    end
    -- Dotfiles are hidden (same convention as Linux)
    if name:sub(1, 1) == "." then return true end
    -- Files without an extension are hidden (executables, scripts without ext, etc.)
    local ext = name:match("%.([^%.]+)$")
    if not ext then return false end
    -- Files whose extension is not on the whitelist are hidden
    return not visible_exts[ext:lower()]
  end
end

-- =============================================================================
-- Plugin spec
-- =============================================================================

return {
  "stevearc/oil.nvim",
  lazy         = false,
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  opts = {
    -- -------------------------------------------------------------------------
    -- Preview pane (shown when C-p is pressed on a text file)
    -- -------------------------------------------------------------------------
    preview_win = {
      update_on_cursor_moved = true,       -- live-update as you move the cursor
      preview_method         = "fast_scratch",
      -- Block non-text files from ever being loaded into a Neovim buffer.
      -- This is a second safety layer on top of safe_preview() — oil checks
      -- this callback before even opening the preview split.
      disable_preview = function(filename)
        local ext = filename:match("%.([^%.]+)$")
        if not ext then return false end
        return not previewable_exts[ext:lower()]
      end,
    },

    -- -------------------------------------------------------------------------
    -- View options
    -- -------------------------------------------------------------------------
    view_options = {
      -- Linux: show everything by default (g. toggles dotfiles).
      -- Windows: use the whitelist-based is_hidden_file() above.
      show_hidden    = not vim.g.is_windows,
      is_hidden_file = is_hidden_file,
    },

    -- -------------------------------------------------------------------------
    -- Keymaps
    -- All descriptions use [oil] prefix so <leader>k search finds them.
    -- set use_default_keymaps = true to keep oil's other built-in bindings.
    -- -------------------------------------------------------------------------
    keymaps = {
      ["g?"]    = { "actions.show_help",     desc = "[oil] show help" },
      ["<CR>"]  = { "actions.select",        desc = "[oil] open" },
      ["<C-s>"] = { "actions.select_vsplit", desc = "[oil] open vsplit" },
      ["<C-h>"] = { "actions.select_split",  desc = "[oil] open split" },
      ["<C-t>"] = { "actions.select_tab",    desc = "[oil] open tab" },
      ["<C-p>"] = { callback = safe_preview, desc = "[oil] preview (text only)" },
      ["<C-c>"] = { "actions.close",         desc = "[oil] close" },
      ["<C-l>"] = { "actions.refresh",       desc = "[oil] refresh" },
      ["-"]     = { "actions.parent",        desc = "[oil] go to parent dir" },
      ["_"]     = { "actions.open_cwd",      desc = "[oil] open cwd" },
      ["`"]     = { "actions.cd",            desc = "[oil] cd to dir" },
      ["~"]     = { "actions.tcd",           desc = "[oil] tcd to dir" },
      ["gs"]    = { "actions.change_sort",   desc = "[oil] change sort" },
      ["gx"]    = { "actions.open_external", desc = "[oil] open with default app" },
      ["g."]    = { "actions.toggle_hidden", desc = "[oil] toggle hidden files" },
    },
    use_default_keymaps = true,
  },
}
