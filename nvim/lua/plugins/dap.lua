return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      
      dapui.setup()
      
      -- Auto-detect venv using VIRTUAL_ENV environment variable
      local function get_python_path()
        local venv = os.getenv("VIRTUAL_ENV")
        if venv then
          return venv .. "/bin/python"
        end
        return vim.fn.exepath("python3") or vim.fn.exepath("python")
      end
      
      require("dap-python").setup(get_python_path())
      
      -- Listeners are the same across versions
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
      
      -- Keybindings (modern syntax)
      local map = vim.keymap.set
      map("n", "<leader>dc", dap.continue, { desc = "Db: Start/Continue" })
      map("n", "<F5>", dap.continue, { desc = "Db: Continue" })

      map("n", "<leader>d1", dap.step_over, { desc = "Db: One line, don't enter function" })
      map("n", "<F10>", dap.step_over, { desc = "Db: Step Over" })

      map("n", "<leader>di", dap.step_into, { desc = "Db: Go into function" })
      map("n", "<F11>", dap.step_into, { desc = "Db: Step Into" })

      map("n", "<leader>do", dap.step_out, { desc = "Db: Run rest of function" })
      map("n", "<F12>", dap.step_out, { desc = "Db: Step Out" })

      map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Db: Toggle Breakpoint" })
      map("n", "<leader>du", dapui.toggle, { desc = "Db: Toggle UI" })
      map("n", "<leader>dx", dap.terminate, { desc = "Db: Stop/Exit session" })
      -- leader dc or F5: start
      -- leader d1 or F10: step over
      -- leader di or F11: step into
      -- leader do or F12: step out
      -- leader db: toggle breakpoint
      -- leader du: toggle UI
      -- leader dx: stop

    end,
  },
}
