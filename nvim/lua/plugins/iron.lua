-- iron.nvim + a herdr external target.
--
-- Same shape as before: one toggle picks where every send goes, and the send
-- keymaps do not care which it is. What changed is the far end — the external
-- target used to be a tmux window, and is now a herdr tab, driven over the
-- herdr control socket by f-herdr (_G.f_herdr). The tmux version is kept as
-- iron.lua.bak.
--
--   Åä   toggle target:  💻 iron (in-nvim split)  <->  📡 herdr (a tab)
--   Åt   bring the target up: IronRepl, or create the herdr tab and start the
--        interpreter in it
--   Åss / Åsf / Ås / Åsb   send line / file / motion / block
--   År   restart, Åf focus, Åh hide, Åc clear
--   Åö   run the project (cargo run, python main.py)
--
--   Åpp  .sh buffers only: run the current line in a bash in a herdr popup,
--        opened in the buffer's own directory. The nvim-driven twin of herdr's
--        prefix+f floating bash. One popup per line — a herdr popup has no
--        pane_id, so it cannot be sent to a second time; it drops into an
--        interactive bash after the command, ctrl-d closes it.
--   Åpf  the same popup with nothing run in it.
--
-- Per filetype the external surface is a named herdr tab, and the name is the
-- one the tmux version used, so muscle memory survives:
--
--   python -> ipyOut     rust -> rustRepl     sh/bash -> bashOut    else termOut
--
-- Two things the socket buys over `tmux send-keys`:
--
--   * the surface is real. f-herdr registers the tab, tags it as ours, and
--     checks it against pane.list before every send — so "the REPL is gone"
--     is an error message instead of keystrokes going nowhere.
--   * submission is a real Enter key press, never a trailing "\n" in the
--     pasted text. herdr delivers text as a paste, and a line editor inserts
--     an embedded newline literally instead of running the line.

return {
  "Vigemus/iron.nvim",
  event = "VeryLazy",
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")

    -- Which python this project uses, anchored on the buffer rather than on
    -- nvim's cwd. Shared with f_visi_h_pane, so the REPL and the tools that
    -- talk to it cannot disagree about which project you are in.
    local fvenv = require("f_venv")

    -- ==========================================
    -- 1. STATE & CONTEXT LOGIC
    -- ==========================================
    local use_herdr_remote = false

    -- Helper: Determine current language context
    local function get_context()
      local ft = vim.bo.filetype
      -- Check first line for custom trigger
      local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
      local is_custom_bash = string.match(first_line, "#%-%-%-%-bash snippet%-%-")

      if ft == "python" then
        local py, is_ipython = fvenv.python(0)
        return {
          ft = "python",
          win_name = "ipyOut",
          -- A shell word, because this is typed at a shell prompt in the tab.
          cmd = vim.fn.shellescape(py) .. (is_ipython and " --no-autoindent" or ""),
          use_magic = is_ipython, -- a pasted block needs a blank line to close
          use_venv = true
        }
      elseif ft == "rust" then
        return {
          ft = "rust",
          win_name = "rustRepl",
          cmd = "evcxr",    -- The Rust REPL command
          use_magic = false,-- Rust REPL doesn't use magic commands like %paste
          use_venv = false
        }
      elseif ft == "sh" or ft == "bash" or is_custom_bash then
        return {
          ft = "sh",
          win_name = "bashOut", -- Separate surface for shell commands
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
    -- 2. HELPER: HERDR UTILS
    -- ==========================================

    -- f-herdr's socket client, looked up at press time: both plugins load
    -- eagerly and their order is not guaranteed. Returns (client, nil) or
    -- (nil, reason).
    local function herdr()
      local fh = _G.f_herdr
      if type(fh) ~= "table" or type(fh.call) ~= "function" then
        return nil, "f-herdr is not loaded (_G.f_herdr is missing)"
      end
      local path, err = fh.socket_path()
      if not path then
        return nil, err
      end
      return fh, nil
    end

    -- The registered surface under this name, but only if it is still there.
    -- f-herdr answers that from pane.list plus its owner tag, so a tab you
    -- closed by hand is dropped rather than sent into.
    local function live_surface(fh, name)
      local rec = fh.get(name)
      if not rec then
        return nil
      end
      local panes = fh.live_panes()
      if panes and fh.check(rec, panes) then
        return rec
      end
      fh.forget(name)
      return nil
    end

    -- A. Bootstrapper (Create Context-Specific herdr tab)
    local function bootstrap_herdr()
      local fh, herdr_err = herdr()
      if not fh then
        vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
        return
      end

      local ctx = get_context()
      local win_name = ctx.win_name

      if live_surface(fh, win_name) then
        vim.notify("⚠️  " .. win_name .. " exists. Kill it manually first.", vim.log.levels.WARN)
        return
      end

      local cwd = vim.fn.getcwd()

      -- Spawn the tab, unfocused: it comes up behind whatever you are doing,
      -- the way `tmux new-window -d` did.
      vim.notify("🚀 Spawning " .. win_name .. " (" .. ctx.ft .. ") in background...", vim.log.levels.INFO)
      local rec, tab_err = fh.new_tab({
        label = win_name,
        name = win_name,
        cwd = cwd,
        focus = false,
      })
      if not rec then
        vim.notify("herdr: could not create " .. win_name .. ": " .. tostring(tab_err), vim.log.levels.ERROR)
        return
      end

      -- Python Specific: Venv. Activating is not how the interpreter is found
      -- (ctx.cmd is already an absolute path) — it is so the tab's shell has
      -- pip and python on PATH once you drop out of the REPL.
      if ctx.use_venv then
        local venv = fvenv.venv(0)
        if venv and vim.fn.filereadable(venv .. "/bin/activate") == 1 then
          fh.run(rec.name, ". " .. vim.fn.shellescape(venv .. "/bin/activate"))
        end
      end

      -- Launch Interpreter (ipython, python3, bash, or evcxr)
      local _, run_err = fh.run(rec.name, ctx.cmd)
      if run_err then
        vim.notify("herdr: could not start " .. ctx.cmd .. ": " .. tostring(run_err), vim.log.levels.ERROR)
      end
    end

    -- B. Send Text to herdr (Context Aware Paste)
    local function send_to_herdr(text)
      if text == nil or text == "" then return end

      local fh, herdr_err = herdr()
      if not fh then
        vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
        return
      end

      local ctx = get_context()
      local rec = live_surface(fh, ctx.win_name)
      if not rec then
        vim.notify("herdr: no surface " .. ctx.win_name .. " — press Åt to create it", vim.log.levels.WARN)
        return
      end

      -- Text and the submitting key press in one request, so nothing can land
      -- between them. An ipython block needs the second Enter to close it;
      -- bash and evcxr take one.
      local keys = ctx.use_magic and { "Enter", "Enter" } or { "Enter" }
      local _, err = fh.send_input(rec.name, text, keys)
      if err then
        vim.notify("herdr: send failed: " .. tostring(err), vim.log.levels.ERROR)
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
    _G.herdr_send_operator = function(type)
      local start_pos = vim.api.nvim_buf_get_mark(0, '[')
      local end_pos = vim.api.nvim_buf_get_mark(0, ']')
      local lines = vim.api.nvim_buf_get_lines(0, start_pos[1]-1, end_pos[1], false)

      if #lines > 0 and type == 'char' then
         lines[#lines] = string.sub(lines[#lines], 1, end_pos[2] + 1)
         lines[1] = string.sub(lines[1], start_pos[2] + 1)
      end
      send_to_herdr(table.concat(lines, "\n"))
    end

    -- ==========================================
    -- 3. IRON SETUP (INTERNAL)
    -- ==========================================
    -- A function, not a list: iron calls it when the REPL is opened, with the
    -- buffer that asked for it (lowlevel.lua resolves repl.command(meta)). A
    -- list is evaluated once here at startup, which froze the interpreter to
    -- whatever nvim's cwd was then — the internal REPL now picks the same
    -- per-buffer venv the external one does.
    local function get_python_command(meta)
       local py, is_ipython = fvenv.python(meta and meta.current_bufnr or 0)
       if is_ipython then return { py, "--no-autoindent" } end
       return { py }
    end

    iron.setup({
      config = {
        scratch_repl = true,
        repl_definition = {
            python = { command = get_python_command, format = require("iron.fts.common").bracketed_paste },
            sh = { command = {"bash"} },
            -- ADDED RUST SUPPORT
            rust = { command = {"evcxr"}, format = require("iron.fts.common").bracketed_paste }
        },
        repl_open_cmd = view.split.vertical.botright(0.45),
      },
      highlight = { italic = true },
      keymaps = {},
      ignore_blank_lines = true,
    })

    -- ==========================================
    -- 4. KEYMAPS (Å Namespace)
    -- ==========================================
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- [Åä] TOGGLE TARGET
    map("n", "Åä", function()
        use_herdr_remote = not use_herdr_remote
        local ctx = get_context()
        local dest = use_herdr_remote and ("📡 herdr ("..ctx.win_name..")") or "💻 Internal (Iron)"
        print("Target: " .. dest)
    end, vim.tbl_extend("force", opts, { desc = "Toggle Iron/herdr Target" }))

    -- [Åt] INITIATE / BOOTSTRAP
    map("n", "Åt", function()
      if use_herdr_remote then bootstrap_herdr() else vim.cmd("IronRepl") end
    end, vim.tbl_extend("force", opts, { desc = "Toggle REPL / Create herdr tab" }))

    -- [Åö] RUN PROJECT (Context Aware)
    -- Rust: runs 'cargo run'
    -- Python: runs 'python main.py'
    map("n", "Åö", function()
        local ctx = get_context()
        local cmd = ""

        if ctx.ft == "rust" then
            cmd = "cargo run"
        elseif ctx.ft == "python" then
            cmd = "python main.py"
        else
            vim.notify("Åö: No run command defined for " .. ctx.ft, vim.log.levels.WARN)
            return
        end

        if use_herdr_remote then
            local fh, herdr_err = herdr()
            if not fh then
              vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
              return
            end
            local rec = live_surface(fh, ctx.win_name)
            if not rec then
              vim.notify("herdr: no surface " .. ctx.win_name .. " — press Åt to create it", vim.log.levels.WARN)
              return
            end
            -- Interrupt whatever is running, then run. ctrl+c is a real key
            -- press, which is the only thing an interpreter reacts to.
            fh.send_keys(rec.name, { "ctrl+c" })
            fh.run(rec.name, cmd)
            vim.notify("🚀 Running Project...", vim.log.levels.INFO)
        else
            vim.notify("Åö only configured for the external herdr target currently.", vim.log.levels.WARN)
        end
    end, vim.tbl_extend("force", opts, { desc = "Run Project (Cargo/Python)" }))

    -- [Åss] SEND LINE
    map("n", "Åss", function()
      if use_herdr_remote then send_to_herdr(vim.api.nvim_get_current_line()) else require("iron.core").send_line() end
    end, vim.tbl_extend("force", opts, { desc = "Send Line (Context Aware)" }))

    -- [Åsf] SEND FILE
    map("n", "Åsf", function()
      if use_herdr_remote then
        local whole_file = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        send_to_herdr(whole_file)
      else
        require("iron.core").send_file()
      end
    end, vim.tbl_extend("force", opts, { desc = "Send File (Context Aware)" }))

    -- [Ås] SEND MOTION
    map("n", "Ås", function()
      if use_herdr_remote then
        vim.go.operatorfunc = "v:lua.herdr_send_operator"
        return "g@"
      else
        return "<cmd>lua require('iron.core').run_motion('send_motion')<CR>"
      end
    end, vim.tbl_extend("force", opts, { expr = true, desc = "Send Motion (Context Aware)" }))

    -- [Ås] SEND VISUAL
    map("x", "Ås", function()
      if use_herdr_remote then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)
        vim.schedule(function() send_to_herdr(get_visual_selection()) end)
      else
        require("iron.core").visual_send()
      end
    end, vim.tbl_extend("force", opts, { desc = "Send Selection (Context Aware)" }))

    -- [Åsb] SEND BLOCK
    map("n", "Åsb", function()
      if use_herdr_remote then
        vim.cmd("normal! vip")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)
        vim.schedule(function() send_to_herdr(get_visual_selection()) end)
      else
        vim.cmd("normal! vip")
        require('iron.core').visual_send()
      end
    end, vim.tbl_extend("force", opts, { desc = "Send Block (Context Aware)" }))


    -- ==========================================
    -- MANAGEMENT (RESTART & CLEAR)
    -- ==========================================

    -- [År] RESTART REPL
    map("n", "År", function()
      if use_herdr_remote then
        local fh, herdr_err = herdr()
        if not fh then
          vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
          return
        end
        local ctx = get_context()
        local rec = live_surface(fh, ctx.win_name)
        if not rec then
          vim.notify("herdr: no surface " .. ctx.win_name .. " — press Åt to create it", vim.log.levels.WARN)
          return
        end

        -- ctrl+d is the universal "end of input": ipython, python, bash and
        -- evcxr all quit on it, so there is no per-language exit command to
        -- get wrong. The tab itself stays; only the interpreter dies, and the
        -- shell underneath takes the start command again.
        fh.send_keys(rec.name, { "ctrl+d" })
        vim.defer_fn(function()
             fh.run(rec.name, ctx.cmd)
        end, 500)

        vim.notify("🔄 Restarting herdr REPL (" .. ctx.win_name .. ")", vim.log.levels.INFO)
      else
        vim.cmd("IronRestart")
      end
    end, vim.tbl_extend("force", opts, { desc = "Restart REPL (Context Aware)" }))

    -- [Åf] FOCUS — the in-nvim REPL window, or herdr's tab
    map("n", "Åf", function()
      if use_herdr_remote then
        local fh, herdr_err = herdr()
        if not fh then
          vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
          return
        end
        local ctx = get_context()
        local rec = live_surface(fh, ctx.win_name)
        if not rec or not rec.tab_id then
          vim.notify("herdr: no surface " .. ctx.win_name .. " — press Åt to create it", vim.log.levels.WARN)
          return
        end
        fh.call("tab.focus", { tab_id = rec.tab_id })
      else
        vim.cmd("IronFocus")
      end
    end, vim.tbl_extend("force", opts, { desc = "Focus REPL (Context Aware)" }))

    map("n", "Åh", "<cmd>IronHide<CR>", vim.tbl_extend("force", opts, { desc = "Iron: Hide UI" }))
    map("n", "Åc", function() require("iron.core").send(nil, string.char(12)) end, vim.tbl_extend("force", opts, { desc = "Iron: Clear Screen" }))

    -- ==========================================
    -- 5. [Åpp] BASH LINE -> HERDR POPUP
    -- ==========================================
    --
    -- The nvim-driven twin of herdr's prefix+f "floating bash in focused pane
    -- cwd", so it is sized to match.
    --
    -- One popup per line, not one popup reused. That is forced by herdr, not
    -- chosen: a popup pane has no pane_id in the socket API — plugin.pane.open
    -- answers {"type":"ok"} with no payload, and the pane is in neither
    -- pane.list nor session.snapshot — so there is nothing to send a second
    -- line to. The command travels in the env map at open time instead, which
    -- is the same route popup.sh already uses for its content.
    --
    -- Consequences worth knowing at the keyboard:
    --   * the popup is focused (an unfocused one is not even the current popup
    --     and its process does not survive), so Åpp takes you out of nvim
    --   * shell state does not carry between two Åpp presses; the popup drops
    --     into an interactive bash after the command, so continue in there
    --   * ctrl-d closes it and returns you to nvim

    local function popup_bash(fh, cmd)
      return fh.popup_shell({
        cmd = cmd,
        cwd = vim.fn.expand("%:p:h") ~= "" and vim.fn.expand("%:p:h") or vim.fn.getcwd(),
        width = "80%",
        height = "60%",
      })
    end

    -- Åpp is for shell buffers: the line under the cursor is a command, and
    -- sending a python line to bash is never what you meant.
    local function require_sh()
      local file = vim.api.nvim_buf_get_name(0)
      local ft = vim.bo.filetype
      if file:match("%.([^.]+)$") == "sh" or ft == "sh" or ft == "bash" then
        return true
      end
      vim.notify("Åpp: this is not a .sh buffer", vim.log.levels.WARN)
      return false
    end

    -- [Åpp] SEND CURRENT LINE TO THE POPUP BASH
    map("n", "Åpp", function()
      if not require_sh() then return end

      local line = vim.trim(vim.api.nvim_get_current_line())
      if line == "" then
        vim.notify("Åpp: empty line", vim.log.levels.WARN)
        return
      end

      local fh, herdr_err = herdr()
      if not fh then
        vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
        return
      end

      local _, popup_err = popup_bash(fh, line)
      if popup_err then
        vim.notify("herdr: no popup: " .. tostring(popup_err), vim.log.levels.ERROR)
      end
    end, vim.tbl_extend("force", opts, { desc = "Send line to bash in a herdr popup" }))

    -- [Åpf] A BARE BASH POPUP, no command — the buffer's directory, nothing run
    map("n", "Åpf", function()
      local fh, herdr_err = herdr()
      if not fh then
        vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
        return
      end
      local _, popup_err = popup_bash(fh, nil)
      if popup_err then
        vim.notify("herdr: no popup: " .. tostring(popup_err), vim.log.levels.ERROR)
      end
    end, vim.tbl_extend("force", opts, { desc = "Open a bash popup in the buffer's directory" }))

    -- Terminal Nav
    map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = "Iron: Exit Term Mode" })
    map('t', '<M-Left>',  '<C-\\><C-n><C-w>h', { desc = "Jump Left" })
    map('t', '<M-Down>',  '<C-\\><C-n><C-w>j', { desc = "Jump Down" })
    map('t', '<M-Up>',    '<C-\\><C-n><C-w>k', { desc = "Jump Up" })
    map('t', '<M-Right>', '<C-\\><C-n><C-w>l', { desc = "Jump Right" })
  end,
}
