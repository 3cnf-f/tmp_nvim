-- =============================================================================
-- config/commands.lua  –  custom user commands
-- =============================================================================

vim.api.nvim_create_user_command("ToggleRelativeNumber", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, {})

-- =============================================================================
-- x0b: normalize line breaks → \x0b on every system-clipboard yank
-- =============================================================================
--
-- When enabled, any yank into the + register (Alt-y / Alt-Y / Alt-y Alt-y)
-- rewrites all line-break variants in the clipboard text to \x0b (VT, 0x0B).
--
-- Why \x0b?
--   In Microsoft Word (and compatible apps), Shift+Enter inserts a "soft"
--   line break — ASCII 11 / \x0b — which keeps text inside the same paragraph
--   instead of starting a new one. Pasting \x0b-separated text into Word
--   therefore lands as a single paragraph with visual line breaks, not as
--   multiple paragraphs separated by blank lines.
--
-- Line-break variants normalised:
--   \r\n  (CRLF — Windows, Notepad)
--   \r    (CR   — old Mac, some apps; Word paragraph break = 0x0D)
--   \n    (LF   — Unix / Linux; Teams soft-return)
--   \x0c  (FF   — Word Ctrl+Enter page break)
--   (Neovim's internal LF separator is already handled via regcontents join)
--
-- Default: ON (true) on Windows, OFF (false) elsewhere.
-- Toggle:  :ToggleX0b   or   <leader>tl
-- Status:  shown as "x0b" in the statusline when active (see lualine.lua).

vim.g.x0b_convert = vim.g.is_windows   -- true on Windows, false on Linux/other

vim.api.nvim_create_user_command("ToggleX0b", function()
  vim.g.x0b_convert = not vim.g.x0b_convert
  vim.notify("x0b line-break convert: " .. (vim.g.x0b_convert and "ON" or "OFF"))
end, { desc = "Toggle x0b line-break normalization on clipboard yank" })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "x0b: rewrite + register — all line-break variants → \\x0b",
  callback = function()
    if not vim.g.x0b_convert then return end
    if vim.v.event.regname ~= "+" then return end

    -- regcontents is a list of lines already split on LF by Neovim.
    -- On Windows (clipboard=unnamedplus) each element can carry a trailing \r
    -- from the OS CRLF clipboard sync. Strip \r per-line first; otherwise
    -- joining with \x0b AND then converting the leftover \r would produce a
    -- double \x0b at every line boundary.
    local lines = {}
    for i, line in ipairs(vim.v.event.regcontents) do
      lines[i] = line:gsub("\r", "")
    end

    -- Join: every line boundary becomes \x0b.
    local text = table.concat(lines, "\x0b")

    -- Handle any remaining FF (Word Ctrl+Enter page break) not covered above.
    text = text:gsub("\x0c", "\x0b")

    vim.fn.setreg("+", text)
  end,
})
