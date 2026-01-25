return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        virt_text_pos = 'eol',
      })
      
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            size = 10,
            position = "bottom",
          },
        },
      })
      
      local function get_python_path()
        local venv = os.getenv("VIRTUAL_ENV")
        if venv then
          return venv .. "/bin/python"
        end
        return vim.fn.exepath("python3") or vim.fn.exepath("python")
      end
      
      require("dap-python").setup(get_python_path())
      
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
      
      local map = vim.keymap.set
      local opts = { noremap = true, silent = true }
      
      -- === Core Debug Controls (å) ===
      map("n", "åc", dap.continue, vim.tbl_extend("force", opts, { desc = "DAP: Continue/Start" }))
      map("n", "å1", dap.step_over, vim.tbl_extend("force", opts, { desc = "DAP: Step over" }))
      map("n", "åi", dap.step_into, vim.tbl_extend("force", opts, { desc = "DAP: Step into" }))
      map("n", "åo", dap.step_out, vim.tbl_extend("force", opts, { desc = "DAP: Step out" }))
      map("n", "åb", dap.toggle_breakpoint, vim.tbl_extend("force", opts, { desc = "DAP: Toggle Breakpoint" }))
      map("n", "åB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, vim.tbl_extend("force", opts, { desc = "DAP: Conditional Breakpoint" }))
      
      -- === UI and Internal REPL ===
      map("n", "år", dap.repl.open, vim.tbl_extend("force", opts, { desc = "DAP: Open Debug Console" }))
      map("n", "åu", dapui.toggle, vim.tbl_extend("force", opts, { desc = "DAP: Toggle UI" }))
      
      -- === Session Control ===
      map("n", "åx", function()
        dap.terminate()
        dapui.close()
      end, vim.tbl_extend("force", opts, { desc = "DAP: Terminate" }))
      
      map("n", "åR", function()
        dap.terminate()
        vim.defer_fn(function() dap.continue() end, 100)
      end, vim.tbl_extend("force", opts, { desc = "DAP: Restart Session" }))
      
      -- === Inspect and Evaluate ===
      map("n", "åh", function()
        require('dap.ui.widgets').hover()
      end, vim.tbl_extend("force", opts, { desc = "DAP: Hover Info" }))
      
      map("n", "åe", function()
        vim.ui.input({ prompt = "Expression: " }, function(expr)
          if expr then require('dap').repl.execute(expr) end
        end)
      end, vim.tbl_extend("force", opts, { desc = "DAP: Eval Expression" }))
      
      map("v", "åe", function()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.api.nvim_buf_get_lines(0, start_pos[2]-1, end_pos[2], false)
        local expr = table.concat(lines, "\n")
        require('dap').repl.execute(expr)
      end, vim.tbl_extend("force", opts, { desc = "DAP: Eval Selection" }))
            
      map("n", "åV", function()
        require("nvim-dap-virtual-text").toggle()
      end, { desc = "DAP: Toggle Virtual Text" })
      
      -- === Watches ===
      map("n", "åw", function()
        local word = vim.fn.expand('<cword>')
        vim.ui.input({ prompt = "Watch expression: ", default = word }, function(expr)
          if expr then
            require('dap.ui').elements.watches.add(expr)
            vim.notify("Added watch: " .. expr)
          end
        end)
      end, vim.tbl_extend("force", opts, { desc = "DAP: Add Watch" }))
      
      -- === Floating Views ===
      map("n", "åv", function() dapui.float_element("scopes", { enter = true }) end, 
        vim.tbl_extend("force", opts, { desc = "DAP: Float Scopes" }))
      
      map("n", "åW", function() dapui.float_element("watches", { enter = true }) end, 
        vim.tbl_extend("force", opts, { desc = "DAP: Float Watches" }))
      
      map("n", "åS", function() dapui.float_element("stacks", { enter = true }) end, 
        vim.tbl_extend("force", opts, { desc = "DAP: Float Stack" }))
      
      -- === DATA DUMPING (Export Variables) ===
      -- åd... = dump variable
      map("n", "ådf", function()
        local word = vim.fn.expand('<cword>')
        local filepath = "/tmp/dump_" .. word .. ".txt"
        local cmd = string.format("import pprint; open('%s','w').write(pprint.pformat(%s))", filepath, word)
        require('dap').repl.execute(cmd)
        vim.notify("Dumped " .. word .. " to " .. filepath)
      end, vim.tbl_extend("force", opts, { desc = "DAP: Dump Var to File" }))
      
      map("n", "åds", function()
        local word = vim.fn.expand('<cword>')
        local filepath = "/tmp/dump_" .. word .. ".txt"
        local cmd = string.format("import pprint; open('%s','w').write(pprint.pformat(%s))", filepath, word)
        require('dap').repl.execute(cmd)
        vim.defer_fn(function() vim.cmd("vsplit " .. filepath) end, 200)
      end, vim.tbl_extend("force", opts, { desc = "DAP: Dump Var to Split" }))

      map("n", "ådt", function()
        local word = vim.fn.expand('<cword>')
        local filepath = "/tmp/dump_" .. word .. ".txt"
        local cmd = string.format("import pprint; open('%s','w').write(pprint.pformat(%s))", filepath, word)
        require('dap').repl.execute(cmd)
        vim.defer_fn(function() vim.cmd("tabnew " .. filepath) end, 200)
      end, vim.tbl_extend("force", opts, { desc = "DAP: Dump Var to Tab" }))

      -- NEW: Dump to Socket (Remote Nvim Server)
      map("n", "ådv", function()
        local word = vim.fn.expand('<cword>')
        local socket_path = "/tmp/nvimsocket"
        local filepath = "/tmp/dump_" .. word .. ".txt"
        
        -- 1. Execute the dump in the current debug session
        local dump_cmd = string.format("import pprint; open('%s','w').write(pprint.pformat(%s))", filepath, word)
        require('dap').repl.execute(dump_cmd)
        
        -- 2. Send command to the socket to open the file in a new tab
        -- We wait slightly to ensure the file is written
        vim.defer_fn(function()
          local remote_cmd = string.format("nvim --server %s --remote-send '<C-\\><C-n>:tabnew %s<CR>'", socket_path, filepath)
          vim.fn.system(remote_cmd)
          vim.notify("Sent " .. word .. " to Remote Nvim Socket")
        end, 200)
      end, vim.tbl_extend("force", opts, { desc = "DAP: Dump Var to Socket" }))

    end,
  },
}
