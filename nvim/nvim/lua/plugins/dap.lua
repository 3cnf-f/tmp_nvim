return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
      "theHamsta/nvim-dap-virtual-text",  -- ← ADD THIS LINE
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        virt_text_pos = 'eol',  -- end of line
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil
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
      
      -- Core debug controls
      map("n", "åc", dap.continue, vim.tbl_extend("force", opts, { desc = "Db: Continue" }))
      map("n", "å1", dap.step_over, vim.tbl_extend("force", opts, { desc = "Db: Step over" }))
      map("n", "åi", dap.step_into, vim.tbl_extend("force", opts, { desc = "Db: Step into" }))
      map("n", "åo", dap.step_out, vim.tbl_extend("force", opts, { desc = "Db: Step out" }))
      map("n", "åb", dap.toggle_breakpoint, vim.tbl_extend("force", opts, { desc = "Db: Breakpoint" }))
      map("n", "åB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, vim.tbl_extend("force", opts, { desc = "Db: Conditional breakpoint" }))
      
      -- UI and REPL
      map("n", "år", dap.repl.open, vim.tbl_extend("force", opts, { desc = "Db: REPL" }))
      map("n", "åu", dapui.toggle, vim.tbl_extend("force", opts, { desc = "Db: Toggle UI" }))
      
      -- Session control
      map("n", "åx", function()
        dap.terminate()
        dapui.close()
      end, vim.tbl_extend("force", opts, { desc = "Db: Quit" }))
      map("n", "åR", function()
        dap.terminate()
        vim.defer_fn(function() dap.continue() end, 100)
      end, vim.tbl_extend("force", opts, { desc = "Db: Restart" }))
      
      -- Inspect and evaluate
      map("n", "åh", function()
        require('dap.ui.widgets').hover()
      end, vim.tbl_extend("force", opts, { desc = "Db: Hover/inspect" }))
      
      map("n", "åe", function()
        vim.ui.input({ prompt = "Expression: " }, function(expr)
          if expr then
            require('dap').repl.execute(expr)
          end
        end)
      end, vim.tbl_extend("force", opts, { desc = "Db: Evaluate expression" }))
      
      map("v", "åe", function()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.api.nvim_buf_get_lines(0, start_pos[2]-1, end_pos[2], false)
        local expr = table.concat(lines, "\n")
        require('dap').repl.execute(expr)
      end, vim.tbl_extend("force", opts, { desc = "Db: Evaluate selection" }))
            
      map("n", "åV", function()

        require("nvim-dap-virtual-text").toggle()
      end, { desc = "Db: Toggle virtual text" })
      
      -- Watches
      map("n", "åw", function()
        local word = vim.fn.expand('<cword>')
        vim.ui.input({ prompt = "Watch expression: ", default = word }, function(expr)
          if expr then
            require('dap.ui').elements.watches.add(expr)
            vim.notify("Added watch: " .. expr)
          end
        end)
      end, vim.tbl_extend("force", opts, { desc = "Db: Add watch" }))
      
      -- View DAP UI elements in floats
      map("n", "åv", function()
        dapui.float_element("scopes", { enter = true })
      end, vim.tbl_extend("force", opts, { desc = "Db: View variables" }))
      
      map("n", "åW", function()
        dapui.float_element("watches", { enter = true })
      end, vim.tbl_extend("force", opts, { desc = "Db: View watches" }))
      
      map("n", "åS", function()
        dapui.float_element("stacks", { enter = true })
      end, vim.tbl_extend("force", opts, { desc = "Db: View stack" }))
      
      -- === DUMP COMMANDS (Grammar: åd/åD + destination) ===
      
      -- ådf: Dump variable to file
      map("n", "ådf", function()
        local word = vim.fn.expand('<cword>')
        local filepath = "/tmp/dump_" .. word .. ".txt"
        local cmd = string.format([[
import pprint
with open('%s', 'w') as f:
    pprint.pprint(%s, stream=f, width=120)
print('Dumped %s to %s')
]], filepath, word, word, filepath)
        require('dap').repl.execute(cmd)
        vim.notify("Dumped " .. word .. " to " .. filepath)
      end, vim.tbl_extend("force", opts, { desc = "Db: Dump var to file" }))
      
      -- åds: Dump variable to split
      map("n", "åds", function()
        local word = vim.fn.expand('<cword>')
        local filepath = "/tmp/dump_" .. word .. ".txt"
        local cmd = string.format([[
import pprint
with open('%s', 'w') as f:
    pprint.pprint(%s, stream=f, width=120)
]], filepath, word)
        require('dap').repl.execute(cmd)
        vim.defer_fn(function()
          vim.cmd("vsplit " .. filepath)
          vim.notify("Dumped " .. word .. " to split")
        end, 200)
      end, vim.tbl_extend("force", opts, { desc = "Db: Dump var to split" }))
      
      -- ådt: Dump variable to new tab
      map("n", "ådt", function()
        local word = vim.fn.expand('<cword>')
        local filepath = "/tmp/dump_" .. word .. ".txt"
        local cmd = string.format([[
import pprint
with open('%s', 'w') as f:
    pprint.pprint(%s, stream=f, width=120)
print('Dumped %s to %s')
]], filepath, word, word, filepath)
        require('dap').repl.execute(cmd)
        vim.defer_fn(function()
          vim.cmd('tabnew ' .. filepath)
          vim.notify("Dumped " .. word .. " to new tab")
        end, 200)
      end, vim.tbl_extend("force", opts, { desc = "Db: Dump var to tab" }))
      
      -- åDf: Dump custom expression to file
      map("n", "åDf", function()
        vim.ui.input({ prompt = "Expression to dump: " }, function(expr)
          if expr then
            local safe_name = expr:gsub("[^%w_]", "_")
            local filepath = "/tmp/dump_" .. safe_name .. ".txt"
            local cmd = string.format([[
import pprint
with open('%s', 'w') as f:
    pprint.pprint(%s, stream=f, width=120)
print('Dumped to %s')
]], filepath, expr, filepath)
            require('dap').repl.execute(cmd)
            vim.notify("Dumped to " .. filepath)
          end
        end)
      end, vim.tbl_extend("force", opts, { desc = "Db: Dump expr to file" }))
      
      -- åDs: Dump custom expression to split
      map("n", "åDs", function()
        vim.ui.input({ prompt = "Expression to dump: " }, function(expr)
          if expr then
            local safe_name = expr:gsub("[^%w_]", "_")
            local filepath = "/tmp/dump_" .. safe_name .. ".txt"
            local cmd = string.format([[
import pprint
with open('%s', 'w') as f:
    pprint.pprint(%s, stream=f, width=120)
]], filepath, expr)
            require('dap').repl.execute(cmd)
            vim.defer_fn(function()
              vim.cmd("vsplit " .. filepath)
              vim.notify("Dumped to split")
            end, 200)
          end
        end)
      end, vim.tbl_extend("force", opts, { desc = "Db: Dump expr to split" }))
      
      -- åDt: Dump custom expression to new tab
      map("n", "åDt", function()
        vim.ui.input({ prompt = "Expression to dump: " }, function(expr)
          if expr then
            local safe_name = expr:gsub("[^%w_]", "_")
            local filepath = "/tmp/dump_" .. safe_name .. ".txt"
            local cmd = string.format([[
import pprint
with open('%s', 'w') as f:
    pprint.pprint(%s, stream=f, width=120)
print('Dumped to %s')
]], filepath, expr, filepath)
            require('dap').repl.execute(cmd)
            vim.defer_fn(function()
              vim.cmd('tabnew ' .. filepath)
              vim.notify("Dumped to new tab")
            end, 200)
          end
        end)
      end, vim.tbl_extend("force", opts, { desc = "Db: Dump expr to tab" }))
      
      -- å[c/1/i/o/b/B/r/u/x/R/h/e/w/v/W/S]
      -- åd[f/s/t] - dump variable to file/split/tab
      -- åD[f/s/t] - dump expression to file/split/tab
    end,
  },
}
