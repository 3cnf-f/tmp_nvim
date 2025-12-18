return {
  "Vigemus/iron.nvim",
  event = "VeryLazy",
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")

    -- 1. SMART INTERPRETER FINDER
    local function get_python_command()
      local cwd = vim.fn.getcwd()
      local venv_names = { ".venv", "venv", "env" }
      
      for _, name in ipairs(venv_names) do
        local local_ipython = cwd .. "/" .. name .. "/bin/ipython"
        local local_python  = cwd .. "/" .. name .. "/bin/python"
        
        if vim.fn.executable(local_ipython) == 1 then
          return { local_ipython, "--no-autoindent" }
        elseif vim.fn.executable(local_python) == 1 then
          return { local_python }
        end
      end

      local global_venv = os.getenv("VIRTUAL_ENV")
      if global_venv then
        if vim.fn.executable(global_venv .. "/bin/ipython") == 1 then
          return { global_venv .. "/bin/ipython", "--no-autoindent" }
        end
        return { global_venv .. "/bin/python" }
      end

      if vim.fn.executable("ipython") == 1 then
        return { "ipython", "--no-autoindent" }
      end
      return { "python3" }
    end

    -- 2. MAIN SETUP
    iron.setup({
      config = {
        scratch_repl = true,
        repl_definition = {
          python = {
            command = get_python_command(),
            format = require("iron.fts.common").bracketed_paste, 
          },
        },
        repl_open_cmd = view.split.vertical.botright(0.45),
      },
      highlight = { italic = true },
      keymaps = {}, 
      ignore_blank_lines = true, 
    })

    -- 3. KUNG FU KEYMAPS (Å = Iron/Interactive)
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- === Management ===
    map("n", "Åt", "<cmd>IronRepl<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Toggle REPL UI" }))
    map("n", "År", "<cmd>IronRestart<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Restart Kernel" }))
    map("n", "Åf", "<cmd>IronFocus<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Focus REPL" }))
    map("n", "Åh", "<cmd>IronHide<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Hide UI" }))
    map("n", "Åc", function() require("iron.core").send(nil, string.char(12)) end, vim.tbl_extend("force", opts, { desc = "Iron: Clear Screen" }))

    -- === Sending Code ===
    
    -- 1. Operator: Ås + motion (Fixed for speed: used <cmd> string instead of lua callback)
    map("n", "Ås", "<cmd>lua require('iron.core').run_motion('send_motion')<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Send Motion" }))
    
    -- 2. Visual: Select + Ås
    map("x", "Ås", function() require("iron.core").visual_send() end, vim.tbl_extend("force", opts, { desc = "Iron: Send Selection" }))
    
    -- 3. Quick Actions
    map("n", "Åss", function() require("iron.core").send_line() end, vim.tbl_extend("force", opts, { desc = "Iron: Send Line" }))
    map("n", "Åsf", function() require("iron.core").send_file() end, vim.tbl_extend("force", opts, { desc = "Iron: Send Whole File" }))
    
    -- 4. Send Block (Explicitly select inner paragraph then send)
    map("n", "Åsb", "vip<cmd>lua require('iron.core').visual_send()<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Send Block (Paragraph)" }))

    -- === Terminal Navigation (Unified Alt-Arrows) ===
    -- Standard Exit to Normal Mode
    map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = "Iron: Exit Term Mode" })
    
    -- Seamless Window Jumping from Terminal Mode
    map('t', '<M-Left>',  '<C-\\><C-n><C-w>h', { desc = "Jump Left" })
    map('t', '<M-Down>',  '<C-\\><C-n><C-w>j', { desc = "Jump Down" })
    map('t', '<M-Up>',    '<C-\\><C-n><C-w>k', { desc = "Jump Up" })
    map('t', '<M-Right>', '<C-\\><C-n><C-w>l', { desc = "Jump Right" })
  end,
}
