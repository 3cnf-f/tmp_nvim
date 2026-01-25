return {
  "Vigemus/iron.nvim",
  event = "VeryLazy",
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")

    -- ==========================================
    -- 1. STATE & CONTEXT LOGIC
    -- ==========================================
    local use_tmux_remote = false

    -- Helper: Determine current language context
    local function get_context()
      local ft = vim.bo.filetype
      -- Check first line for custom trigger
      local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
      local is_custom_bash = string.match(first_line, "#%-%-%-%-bash snippet%-%-")

      if ft == "python" then
        return {
          ft = "python",
          win_name = "ipyOut",
          cmd = "ipython",
          use_magic = true, -- Use %paste for IPython
          use_venv = true
        }
      elseif ft == "sh" or ft == "bash" or is_custom_bash then
        return {
          ft = "sh",
          win_name = "bashOut", -- Separate window for shell commands
          cmd = "bash",
          use_magic = false,    -- Raw paste for Bash
          use_venv = false
        }
      else
        -- Fallback default (treat as generic shell)
        return {
          ft = "sh",
          win_name = "termOut",
          cmd = "bash",
          use_magic = false,
          use_venv = false
        }
      end
    end

    -- ==========================================
    -- 2. HELPER: TMUX UTILS
    -- ==========================================
    
    -- Function to spawn the Nvim Socket Server with automatic cleanup
    local function spawn_nvim_server()
      local win_name = "nvimServer"
      local socket_path = "/tmp/nvimsocket"
      
      -- Check if window exists
      local handle = io.popen("tmux list-windows -F '#{window_name}'")
      local result = handle:read("*a")
      handle:close()

      if string.find(result, "^" .. win_name .. "\n") or string.find(result, "\n" .. win_name .. "\n") then
        vim.notify("🔗 Socket server window '" .. win_name .. "' already exists.", vim.log.levels.WARN)
        return
      end

      vim.notify("⚡ Cleaning socket and starting Nvim Server...", vim.log.levels.INFO)
      
      -- 1. Spawn Window
      vim.fn.system({"tmux", "new-window", "-d", "-n", win_name})
      
      -- 2. Cleanup stale socket and start nvim
      -- We run 'rm -f' first to ensure the socket path is available
      local cmd = string.format("rm -f %s && nvim --listen %s", socket_path, socket_path)
      vim.fn.system({"tmux", "send-keys", "-t", ":" .. win_name, cmd, "Enter"})
    end

    -- A. Bootstrapper (Create Context-Specific Window)
    local function bootstrap_tmux()
      local ctx = get_context()
      local win_name = ctx.win_name

      -- Check if window exists
      local handle = io.popen("tmux list-windows -F '#{window_name}'")
      local result = handle:read("*a")
      handle:close()

      if string.find(result, "^" .. win_name .. "\n") or string.find(result, "\n" .. win_name .. "\n") then
        vim.notify("⚠️  " .. win_name .. " exists. Kill it manually first.", vim.log.levels.WARN)
        return
      end

      local cwd = vim.fn.getcwd()
      
      -- Spawn Window
      vim.notify("🚀 Spawning " .. win_name .. " (" .. ctx.ft .. ") in background...", vim.log.levels.INFO)
      vim.fn.system({"tmux", "new-window", "-d", "-n", win_name})
      vim.fn.system({"tmux", "send-keys", "-t", ":" .. win_name, "cd " .. cwd, "Enter"})
      
      -- Python Specific: Venv & IPython
      if ctx.use_venv then
        local venv = os.getenv("VIRTUAL_ENV") or ""
        if venv == "" then
          for _, name in ipairs({ ".venv", "venv", "env" }) do
            if vim.fn.isdirectory(cwd .. "/" .. name) == 1 then venv = cwd .. "/" .. name break end
          end
        end
        if venv ~= "" then vim.fn.system({"tmux", "send-keys", "-t", ":" .. win_name, "source " .. venv .. "/bin/activate", "Enter"}) end
      end

      -- Launch Interpreter (ipython or bash)
      vim.fn.system({"tmux", "send-keys", "-t", ":" .. win_name, ctx.cmd, "Enter"})
    end

    -- B. Send Text to Tmux (Context Aware Paste)
    local function send_to_tmux(text)
      if text == nil or text == "" then return end
      local ctx = get_context()

      -- 1. Load text into buffer
      vim.fn.system({"tmux", "load-buffer", "-"}, text)
      
      -- 2. Paste Logic
      if ctx.use_magic then
        -- Python/IPython: Use %paste magic
        vim.fn.system({"tmux", "paste-buffer", "-d", "-p", "-t", ":" .. ctx.win_name})
        -- Double Enter for IPython block completion
        vim.fn.system({"tmux", "send-keys", "-t", ":" .. ctx.win_name, "Enter", "Enter"})
      else
        -- Bash: Raw paste (Bracketed paste -p is usually safe/good for bash too)
        vim.fn.system({"tmux", "paste-buffer", "-d", "-p", "-t", ":" .. ctx.win_name})
        -- Single Enter usually enough for Bash, but extra doesn't hurt
        vim.fn.system({"tmux", "send-keys", "-t", ":" .. ctx.win_name, "Enter"})
      end
    end

    -- C. Get Visual Selection
    local function get_visual_selection()
      local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
      local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
      local lines = vim.fn.getline(csrow, cerow)
      if #lines == 0 then return "" end
      lines[#lines] = string.sub(lines[#lines], 1, cecol)
      lines[1] = string.sub(lines[1], cscol)
      return table.concat(lines, "\n")
    end

    -- D. Operator Function
    _G.tmux_send_operator = function(type)
      local start_pos = vim.api.nvim_buf_get_mark(0, '[')
      local end_pos = vim.api.nvim_buf_get_mark(0, ']')
      local lines = vim.api.nvim_buf_get_lines(0, start_pos[1]-1, end_pos[1], false)
      
      if #lines > 0 and type == 'char' then
         lines[#lines] = string.sub(lines[#lines], 1, end_pos[2] + 1)
         lines[1] = string.sub(lines[1], start_pos[2] + 1)
      end
      send_to_tmux(table.concat(lines, "\n"))
    end

    -- ==========================================
    -- 3. IRON SETUP (INTERNAL)
    -- ==========================================
    local function get_python_command()
       local cwd = vim.fn.getcwd()
       local venv_names = { ".venv", "venv", "env" }
       for _, name in ipairs(venv_names) do
         local local_ipython = cwd .. "/" .. name .. "/bin/ipython"
         local local_python  = cwd .. "/" .. name .. "/bin/python"
         if vim.fn.executable(local_ipython) == 1 then return { local_ipython, "--no-autoindent" }
         elseif vim.fn.executable(local_python) == 1 then return { local_python } end
       end
       local global_venv = os.getenv("VIRTUAL_ENV")
       if global_venv then
         if vim.fn.executable(global_venv .. "/bin/ipython") == 1 then return { global_venv .. "/bin/ipython", "--no-autoindent" } end
         return { global_venv .. "/bin/python" }
       end
       if vim.fn.executable("ipython") == 1 then return { "ipython", "--no-autoindent" } end
       return { "python3" }
    end

    iron.setup({
      config = {
        scratch_repl = true,
        repl_definition = { 
            python = { command = get_python_command(), format = require("iron.fts.common").bracketed_paste },
            sh = { command = {"bash"} } 
        },
        repl_open_cmd = view.split.vertical.botright(0.45),
      },
      highlight = { italic = true },
      keymaps = {}, 
      ignore_blank_lines = true, 
    })

    -- ==========================================
    -- 4. KEYMAPS (Å/å Namespace)
    -- ==========================================
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- [å] mappings
    map("n", "åt", function()
      spawn_nvim_server()
    end, vim.tbl_extend("force", opts, { desc = "Tmux: Start Nvim Socket Server" }))

    -- [Å] mappings
    map("n", "Åä", function()
        use_tmux_remote = not use_tmux_remote
        local ctx = get_context()
        local dest = use_tmux_remote and ("📡 External ("..ctx.win_name..")") or "💻 Internal (Iron)"
        print("Target: " .. dest)
    end, vim.tbl_extend("force", opts, { desc = "Toggle Iron/Tmux Target" }))

    map("n", "Åt", function()
      if use_tmux_remote then bootstrap_tmux() else vim.cmd("IronRepl") end
    end, vim.tbl_extend("force", opts, { desc = "Toggle REPL / Create Tmux" }))

    map("n", "Åss", function() 
      if use_tmux_remote then send_to_tmux(vim.api.nvim_get_current_line()) else require("iron.core").send_line() end
    end, vim.tbl_extend("force", opts, { desc = "Send Line (Context Aware)" }))

    map("n", "Åsf", function()
      if use_tmux_remote then 
        local whole_file = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        send_to_tmux(whole_file)
      else 
        require("iron.core").send_file() 
      end
    end, vim.tbl_extend("force", opts, { desc = "Send File (Context Aware)" }))

    map("n", "Ås", function()
      if use_tmux_remote then
        vim.go.operatorfunc = "v:lua.tmux_send_operator"
        return "g@"
      else
        return "<cmd>lua require('iron.core').run_motion('send_motion')<CR>"
      end
    end, vim.tbl_extend("force", opts, { expr = true, desc = "Send Motion (Context Aware)" }))

    map("x", "Ås", function()
      if use_tmux_remote then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)
        vim.schedule(function() send_to_tmux(get_visual_selection()) end)
      else
        require("iron.core").visual_send()
      end
    end, vim.tbl_extend("force", opts, { desc = "Send Selection (Context Aware)" }))

    map("n", "Åsb", function()
      if use_tmux_remote then
        vim.cmd("normal! vip")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)
        vim.schedule(function() send_to_tmux(get_visual_selection()) end)
      else
        vim.cmd("normal! vip")
        require('iron.core').visual_send()
      end
    end, vim.tbl_extend("force", opts, { desc = "Send Block (Context Aware)" }))

    map("n", "År", function()
      if use_tmux_remote then
        local ctx = get_context()
        if ctx.ft == "python" then
           local target = ":" .. ctx.win_name
           vim.fn.system({"tmux", "send-keys", "-t", target, "quit()", "Enter"})
           vim.fn.system({"tmux", "send-keys", "-t", target, "ipython", "Enter"})
           vim.notify("🔄 Restarting Tmux Session (" .. ctx.win_name .. ")", vim.log.levels.INFO)
        else
           vim.notify("⚠️  Tmux restart is only configured for Python", vim.log.levels.WARN)
        end
      else
        vim.cmd("IronRestart")
      end
    end, vim.tbl_extend("force", opts, { desc = "Restart REPL (Context Aware)" }))

    map("n", "Åf", "<cmd>IronFocus<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Focus REPL" }))
    map("n", "Åh", "<cmd>IronHide<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Hide UI" }))
    map("n", "Åc", function() require("iron.core").send(nil, string.char(12)) end, vim.tbl_extend("force", opts, { desc = "Iron: Clear Screen" }))

    map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = "Iron: Exit Term Mode" })
    map('t', '<M-Left>',  '<C-\\><C-n><C-w>h', { desc = "Jump Left" })
    map('t', '<M-Down>',  '<C-\\><C-n><C-w>j', { desc = "Jump Down" })
    map('t', '<M-Up>',    '<C-\\><C-n><C-w>k', { desc = "Jump Up" })
    map('t', '<M-Right>', '<C-\\><C-n><C-w>l', { desc = "Jump Right" })
  end,
}
