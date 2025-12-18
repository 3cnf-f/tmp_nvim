return {
  "Vigemus/iron.nvim",
  event = "VeryLazy",
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")
    
    -- === SMART INTERPRETER FINDER ===
    -- Looks for .venv/bin/ipython locally, then falls back to system.
    local function get_python_command()
      local cwd = vim.fn.getcwd()
      local venv_names = { ".venv", "venv", "env" }
      
      -- 1. Search for local venv in current project
      for _, name in ipairs(venv_names) do
        local local_ipython = cwd .. "/" .. name .. "/bin/ipython"
        local local_python  = cwd .. "/" .. name .. "/bin/python"
        
        if vim.fn.executable(local_ipython) == 1 then
          return { local_ipython, "--no-autoindent" }
        elseif vim.fn.executable(local_python) == 1 then
          return { local_python }
        end
      end

      -- 2. Check active global VIRTUAL_ENV
      local global_venv = os.getenv("VIRTUAL_ENV")
      if global_venv then
        if vim.fn.executable(global_venv .. "/bin/ipython") == 1 then
          return { global_venv .. "/bin/ipython", "--no-autoindent" }
        end
        return { global_venv .. "/bin/python" }
      end

      -- 3. System Fallback
      if vim.fn.executable("ipython") == 1 then
        return { "ipython", "--no-autoindent" }
      end
      return { "python3" }
    end

    iron.setup({
      config = {
        scratch_repl = true,
        repl_definition = {
          python = {
            -- Uses current folder + .venv + bin + ipython
            command = { vim.fn.getcwd() .. "/.venv/bin/ipython", "--no-autoindent" },
            format = require("iron.fts.common").bracketed_paste, 
          },
        },
        -- Vertical split, 40% width
        repl_open_cmd = view.split.vertical.botright(0.40),
      },
      highlight = { italic = true },
      keymaps = {}, 
      ignore_blank_lines = true, 
    })

    -- === KUNG FU KEYMAPS ===
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true, desc = "Iron: " }

    map("n", "åI", "<cmd>IronRepl<CR>", vim.tbl_extend("force", opts, { desc = "Toggle REPL" }))
    map("n", "åR", "<cmd>IronRestart<CR>", vim.tbl_extend("force", opts, { desc = "Restart REPL" }))
    map("n", "åC", function() require("iron.core").send(nil, string.char(12)) end, vim.tbl_extend("force", opts, { desc = "Clear Screen" }))
    
    -- Sending Code
    map("n", "ås", "<cmd>IronFocus<cr>", vim.tbl_extend("force", opts, { desc = "Send Motion" }))
    map("n", "åss", function() require("iron.core").send_line() end, vim.tbl_extend("force", opts, { desc = "Send Line" }))
    map("n", "åsf", function() require("iron.core").send_file() end, vim.tbl_extend("force", opts, { desc = "Send File" }))
    map("v", "ås", function() require("iron.core").visual_send() end, vim.tbl_extend("force", opts, { desc = "Send Visual" }))
    
    -- Jupyter-style Block Execution (Paragraph)
    map("n", "åsb", function() require("iron.core").run_motion("ip") end, vim.tbl_extend("force", opts, { desc = "Send Block" }))
  end,
}
