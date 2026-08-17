-- iron.nvim + a herdr external target.
--
-- Same shape as before: one toggle picks where every send goes, and the send
-- keymaps do not care which it is. What changed is the far end — the external
-- target used to be a tmux window, and is now a herdr tab, driven over the
-- herdr control socket by f-herdr (_G.f_herdr). The tmux version is kept as
-- iron.lua.bak.
--
--   Åä   open the target menu (f_target): pick which destination to change —
--        REPL, visidata, or Åpp bash — then pick the destination itself. The
--        REPL choice replaces what used to be a two-state toggle:
--          💻 iron    in-nvim split                              [default]
--          🏠 local   auto-named tab in this workspace, per filetype
--          📡 pane    one specific pane, any workspace, any session
--   Åt   bring the target up: IronRepl; or create the herdr tab and start the
--        interpreter in it; or, for a pinned pane, report what is already
--        running there and start the interpreter only if it is a bare shell
--   Åss / Åsf / Ås / Åsb   send line / file / motion / block
--   År   restart, Åf focus, Åh hide, Åc clear
--   Åö   run the project (cargo run, python main.py)
--
-- Åp is the bash twin of Ås, .sh buffers only, and runs where Åä's "Åpp bash"
-- target says — a reusable split in this workspace (default), a reusable split
-- in any workspace of any session, or a one-shot herdr popup:
--
--   Åp<motion>  run a motion or text object      Åps  run the current line
--   Åp (visual) run the selection                Åpp  the same (alias)
--   Åpb         run the block (vip)              Åpf  run the whole file
--   Åpo         open/focus the bash, run nothing
--
-- Being an operator is what makes Åp worth having: everything mapped in
-- operator-pending mode comes along for free. From treesitter-textobjects,
-- Åpif / Åpaf / Åpac / Åpal / Åpai and so on; from flash.nvim, Åpä jumps to a
-- label and runs to there, ÅpÄ runs a treesitter-selected node, Åpr runs
-- remotely; plus the repeatable f/F/t/T and ; and ,.
--
-- The pane modes and the popup differ in one way that matters: the popup has no
-- pane_id in the socket API, so it is one popup per press and no shell state
-- survives. A pane does have one, so Åp reuses a single pane and a cd or an
-- export carries to the next press. That is also why Åpf pastes the file's
-- contents rather than running `bash <file>` — a subprocess would discard them.
--
-- Åt on a python target does more than start an interpreter. It cds to nvim's
-- cwd, creates the venv if there is none, copies f_visi_nvim_tool.py in for Åv
-- to import, pip installs visidata and ipython when they are missing, and then
-- starts ipython — as one shell line, so a slow pip cannot race the next step.
-- bash and rust just get their one word, and no cd.
--
-- For the 🏠 local REPL target the surface is a named herdr tab per filetype,
-- and the name is the one the tmux version used, so muscle memory survives:
--
--   python -> ipyOut     rust -> rustRepl     sh/bash -> bashOut    else termOut
--
-- A 📡 pinned pane is deliberately filetype-blind: pin one and python and bash
-- sends both go there. That is why the number of Enters that submits a paste is
-- decided by asking the pane what it is running (f_herdr.process_summary), not
-- by the buffer's filetype — an ipython block needs a blank line to close it and
-- a bash line does not, so guessing from the buffer would corrupt the paste.
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

    -- Where sends go. Shared with f_visi_h_pane so the two cannot disagree
    -- about which REPL is "yours"; see the header of f_target.lua.
    local ftarget = require("f_target")

    -- ==========================================
    -- 1. STATE & CONTEXT LOGIC
    -- ==========================================
    --
    -- The old `use_herdr_remote` boolean is now ftarget.repl.kind, which has
    -- three values rather than two: "iron" and "local" are exactly the old false
    -- and true, and "pane" is the new one.
    local function repl_kind()
      return ftarget.repl.kind
    end

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

    -- Everything a pane needs before it can be a python REPL that Åv can also
    -- export from, as ONE compound shell line.
    --
    -- One line, not a run() per step, and that is not a style choice. run() paces
    -- itself by waiting for a prompt and then for its own echo, roughly three
    -- seconds before it gives up and sends anyway. A pip install takes far longer
    -- than that, so a second run() would type `ipython` into the middle of the
    -- install. Letting the shell sequence it with `;` removes the race outright.
    --
    -- In order:
    --   cd     nvim's cwd, so the venv and the csv Åv writes agree on "here"
    --   venv   f_venv's walk-up answer if it found one, else .venv right here.
    --          Using the discovered path rather than a literal ./.venv matters
    --          for a buffer in src/deep/: the project's venv is a few levels up
    --          and creating a second one beside the file would be wrong.
    --   cp     f_visi_nvim_tool.py into the cwd, which is what Åv's export line
    --          imports once it puts that directory on sys.path
    --   pip    visidata (Åv's viewer) and ipython, each only when missing, so a
    --          second Åt costs a couple of imports instead of two downloads
    --   run    ipython by name, resolved through the venv we just activated —
    --          not by absolute path, which may not have existed yet when
    --          get_context() asked f_venv for it
    local function python_bootstrap_cmd()
      local cwd = vim.fn.getcwd()
      local venv = fvenv.venv(0) or (cwd .. "/.venv")
      local tool = vim.fn.stdpath("config") .. "/lua/plugins/f_visi_nvim_tool.py"
      local sq = vim.fn.shellescape
      return table.concat({
        "cd " .. sq(cwd),
        "{ [ -d " .. sq(venv) .. " ] || python3 -m venv " .. sq(venv) .. "; }",
        "cp " .. sq(tool) .. " .",
        ". " .. sq(venv .. "/bin/activate"),
        "python -c 'import visidata' 2>/dev/null || pip install visidata",
        "python -c 'import IPython' 2>/dev/null || pip install ipython",
        "ipython --no-autoindent",
      }, "; ")
    end

    -- What to type into a freshly created surface to make it the REPL this
    -- buffer wants. python gets the venv bootstrap above; bash and evcxr are a
    -- single word and need no cwd of their own.
    local function start_cmd(ctx)
      if ctx.use_venv then
        return python_bootstrap_cmd()
      end
      return ctx.cmd
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

      -- Launch the interpreter. For python that is the venv bootstrap — create
      -- the venv if absent, copy Åv's helper in, pip install visidata and
      -- ipython if missing, then ipython — as one shell line. For bash and evcxr
      -- it is just the word.
      local _, run_err = fh.run(rec.name, start_cmd(ctx))
      if run_err then
        vim.notify("herdr: could not start " .. ctx.ft .. " REPL: " .. tostring(run_err), vim.log.levels.ERROR)
        return
      end
      if ctx.use_venv then
        vim.notify("🐍 " .. win_name .. ": venv + visidata + ipython (first run downloads)", vim.log.levels.INFO)
      end
    end

    -- What actually submits a pasted block in this destination.
    --
    -- An ipython block needs a second Enter to close it; bash and evcxr take
    -- one. For a tab we created, ctx.use_magic already knows, because we chose
    -- the interpreter. For a pinned pane we did not, and the pin is
    -- filetype-blind by design, so ask the pane instead of assuming: guessing
    -- wrong here does not merely pick the wrong REPL, it mangles the paste.
    --
    -- One extra round-trip per send, on a unix socket, against three already in
    -- flight. Worth it.
    local function submit_keys(fh, ctx, t)
      -- Ask the pane, for BOTH herdr kinds. For a pinned pane we never knew what
      -- was in it. For a local tab we thought we did — but ctx.use_magic came
      -- from f_venv at *this* keypress, and Åt may since have pip-installed
      -- ipython into a venv that had none when the tab was made, which flips the
      -- answer from one Enter to two.
      local probe
      if t.kind == "pane" then
        probe = t
      elseif t.kind == "local" then
        local rec = fh.get(ctx.win_name)
        if rec and rec.pane_id then
          probe = { is_this = true, pane_id = rec.pane_id, terminal_id = rec.terminal_id }
        end
      end

      if probe then
        local info = fh.process_summary(probe)
        local name = info and info.name
        if name == "ipython" then
          return { "Enter", "Enter" }, name
        elseif name then
          return { "Enter" }, name
        end
        -- Nothing legible running: fall through to the buffer's own answer.
      end
      return ctx.use_magic and { "Enter", "Enter" } or { "Enter" }, nil
    end

    -- A bare login shell is a pane that is waiting for work; anything else is a
    -- pane already doing something, and the difference decides whether it is
    -- safe to type an interpreter into it or to ctrl+d it.
    local BARE_SHELLS = {
      bash = true, zsh = true, sh = true, fish = true, dash = true, ksh = true, ash = true,
    }

    -- Is what is running in a pinned pane already the interpreter this buffer
    -- wants? Returns true / false, or nil when we cannot tell.
    local function target_ready(name, ctx)
      if not name then
        return nil
      end
      if ctx.ft == "python" then
        return name == "ipython" or name:match("^python") ~= nil
      elseif ctx.ft == "rust" then
        return name:find("evcxr", 1, true) ~= nil
      end
      -- sh: a shell is the interpreter.
      return BARE_SHELLS[name] == true
    end

    -- A'. Åt for a pinned pane. There is no surface to create — someone else
    -- made it — so this reports rather than builds, and starts the interpreter
    -- only when the pane is demonstrably idle at a shell prompt. Typing a REPL
    -- into a pane that is running something else would interrupt work that is
    -- not ours.
    local function bootstrap_pane(fh, ctx, t)
      local pane, verr = fh.verify_target(t)
      if not pane then
        vim.notify("herdr: " .. tostring(verr) .. " — press Åä to pick another", vim.log.levels.ERROR)
        return
      end

      local info = fh.process_summary(t)
      local name = info and info.name
      local ready = target_ready(name, ctx)

      if ready then
        vim.notify(string.format("📡 %s already running %s — ready", fh.target_label(t), name),
          vim.log.levels.INFO)
        return
      end

      if not (name and BARE_SHELLS[name]) then
        vim.notify(string.format(
          "📡 %s is running %s, not a shell — not starting %s in it. Send anyway with Åss, or Åä to repick.",
          fh.target_label(t), tostring(name or "something unrecognised"), ctx.ft), vim.log.levels.WARN)
        return
      end

      -- Idle at a prompt: safe to start the interpreter. A python pane gets the
      -- same bootstrap a local tab does — cd to nvim's cwd, venv, Åv's helper,
      -- pip installs, ipython — so a pinned pane is as usable for Åv as one we
      -- made ourselves. It is a real intervention in a pane we do not own, which
      -- is exactly why it only happens past the bare-shell check above.
      local _, run_err = fh.run_on(t, start_cmd(ctx))
      if run_err then
        vim.notify("herdr: could not start " .. ctx.ft .. " REPL: " .. tostring(run_err), vim.log.levels.ERROR)
        return
      end
      vim.notify(string.format("🚀 started %s in %s%s", ctx.ft, fh.target_label(t),
        ctx.use_venv and "  (venv + visidata + ipython; first run downloads)" or ""), vim.log.levels.INFO)
    end

    -- B. Send Text to the current herdr destination (Context Aware Paste).
    -- Handles the "local" (named tab) and "pane" (pinned) kinds; "iron" never
    -- reaches here, the keymaps route it to iron.nvim directly.
    local function send_to_herdr(text)
      if text == nil or text == "" then return end

      local fh, herdr_err = herdr()
      if not fh then
        vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
        return
      end

      local ctx = get_context()
      local t = ftarget.repl

      -- Text and the submitting key press in one request, so nothing can land
      -- between them.
      if t.kind == "pane" then
        local keys = submit_keys(fh, ctx, t)
        -- send_input_to verifies the pane by terminal_id first, so a pane that
        -- has since closed is an error rather than keystrokes into a stranger.
        local _, err = fh.send_input_to(t, text, keys)
        if err then
          vim.notify("herdr: send failed: " .. tostring(err), vim.log.levels.ERROR)
        end
        return
      end

      local rec = live_surface(fh, ctx.win_name)
      if not rec then
        vim.notify("herdr: no surface " .. ctx.win_name .. " — press Åt to create it", vim.log.levels.WARN)
        return
      end
      local keys = submit_keys(fh, ctx, t)
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

    -- [Åä] PICK TARGET — menu first (REPL / visidata / Åpp bash), then the
    -- destination. Replaces the old two-state toggle; "iron" and "local" are
    -- the two states it used to have.
    map("n", "Åä", function()
      ftarget.menu()
    end, vim.tbl_extend("force", opts, { desc = "Pick herdr target (REPL / visidata / Åpp)" }))

    -- [Åt] INITIATE / BOOTSTRAP
    map("n", "Åt", function()
      local kind = repl_kind()
      if kind == "iron" then
        vim.cmd("IronRepl")
      elseif kind == "local" then
        bootstrap_herdr()
      else
        local fh, herdr_err = herdr()
        if not fh then
          vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
          return
        end
        bootstrap_pane(fh, get_context(), ftarget.repl)
      end
    end, vim.tbl_extend("force", opts, { desc = "Toggle REPL / create herdr tab / check pinned pane" }))

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

        if repl_kind() == "iron" then
            vim.notify("Åö only configured for the external herdr target currently.", vim.log.levels.WARN)
            return
        end

        local fh, herdr_err = herdr()
        if not fh then
          vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
          return
        end

        -- Interrupt whatever is running, then run. ctrl+c is a real key press,
        -- which is the only thing an interpreter reacts to.
        if repl_kind() == "pane" then
            local t = ftarget.repl
            local _, err = fh.send_keys_to(t, { "ctrl+c" })
            if err then
              vim.notify("herdr: " .. tostring(err), vim.log.levels.ERROR)
              return
            end
            fh.run_on(t, cmd)
        else
            local rec = live_surface(fh, ctx.win_name)
            if not rec then
              vim.notify("herdr: no surface " .. ctx.win_name .. " — press Åt to create it", vim.log.levels.WARN)
              return
            end
            fh.send_keys(rec.name, { "ctrl+c" })
            fh.run(rec.name, cmd)
        end
        vim.notify("🚀 Running Project...", vim.log.levels.INFO)
    end, vim.tbl_extend("force", opts, { desc = "Run Project (Cargo/Python)" }))

    -- [Åss] SEND LINE
    map("n", "Åss", function()
      if repl_kind() ~= "iron" then send_to_herdr(vim.api.nvim_get_current_line()) else require("iron.core").send_line() end
    end, vim.tbl_extend("force", opts, { desc = "Send Line (Context Aware)" }))

    -- [Åsf] SEND FILE
    map("n", "Åsf", function()
      if repl_kind() ~= "iron" then
        local whole_file = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        send_to_herdr(whole_file)
      else
        require("iron.core").send_file()
      end
    end, vim.tbl_extend("force", opts, { desc = "Send File (Context Aware)" }))

    -- [Ås] SEND MOTION
    map("n", "Ås", function()
      if repl_kind() ~= "iron" then
        vim.go.operatorfunc = "v:lua.herdr_send_operator"
        return "g@"
      else
        return "<cmd>lua require('iron.core').run_motion('send_motion')<CR>"
      end
    end, vim.tbl_extend("force", opts, { expr = true, desc = "Send Motion (Context Aware)" }))

    -- [Ås] SEND VISUAL
    map("x", "Ås", function()
      if repl_kind() ~= "iron" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)
        vim.schedule(function() send_to_herdr(get_visual_selection()) end)
      else
        require("iron.core").visual_send()
      end
    end, vim.tbl_extend("force", opts, { desc = "Send Selection (Context Aware)" }))

    -- [Åsb] SEND BLOCK
    map("n", "Åsb", function()
      if repl_kind() ~= "iron" then
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
      if repl_kind() ~= "iron" then
        local fh, herdr_err = herdr()
        if not fh then
          vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
          return
        end
        local ctx = get_context()

        -- ctrl+d is the universal "end of input": ipython, python, bash and
        -- evcxr all quit on it, so there is no per-language exit command to
        -- get wrong. In a tab we made, the tab stays and only the interpreter
        -- dies, and the shell underneath takes the start command again.
        if repl_kind() == "pane" then
          local t = ftarget.repl
          -- In a pane we did NOT make, that same ctrl+d is dangerous: sent to a
          -- bare shell it ends the shell, which closes someone else's pane. So
          -- only restart something that is demonstrably an interpreter, and
          -- refuse otherwise rather than guessing.
          local pane, verr = fh.verify_target(t)
          if not pane then
            vim.notify("herdr: " .. tostring(verr), vim.log.levels.ERROR)
            return
          end
          local info = fh.process_summary(t)
          local name = info and info.name
          if not name or BARE_SHELLS[name] then
            vim.notify(string.format(
              "År: %s is at a bare %s prompt, not running a REPL — ctrl+d there would close the pane. "
              .. "Press Åt to start one.", fh.target_label(t), tostring(name or "shell")),
              vim.log.levels.WARN)
            return
          end

          fh.send_keys_to(t, { "ctrl+d" })
          vim.defer_fn(function()
            fh.run_on(t, start_cmd(ctx))
          end, 500)
          vim.notify(string.format("🔄 Restarting %s in %s", ctx.ft, fh.target_label(t)), vim.log.levels.INFO)
          return
        end

        local rec = live_surface(fh, ctx.win_name)
        if not rec then
          vim.notify("herdr: no surface " .. ctx.win_name .. " — press Åt to create it", vim.log.levels.WARN)
          return
        end
        fh.send_keys(rec.name, { "ctrl+d" })
        vim.defer_fn(function()
             fh.run(rec.name, start_cmd(ctx))
        end, 500)

        vim.notify("🔄 Restarting herdr REPL (" .. ctx.win_name .. ")", vim.log.levels.INFO)
      else
        vim.cmd("IronRestart")
      end
    end, vim.tbl_extend("force", opts, { desc = "Restart REPL (Context Aware)" }))

    -- [Åf] FOCUS — the in-nvim REPL window, or herdr's tab
    map("n", "Åf", function()
      if repl_kind() ~= "iron" then
        local fh, herdr_err = herdr()
        if not fh then
          vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
          return
        end
        -- A pinned pane may be in another workspace, or another session
        -- entirely, so focusing it means focusing its workspace first;
        -- focus_target does both.
        if repl_kind() == "pane" then
          local _, err = fh.focus_target(ftarget.repl)
          if err then
            vim.notify("herdr: " .. tostring(err), vim.log.levels.ERROR)
          end
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
    -- 5. [Åpp] BASH LINE -> POPUP OR REUSABLE PANE
    -- ==========================================
    --
    -- Three destinations, set from Åä ("Åpp bash"):
    --
    --   local_pane   [default] a reusable split in this workspace
    --   remote_pane            a reusable split in a chosen workspace, any session
    --   popup                  the original one-shot herdr popup
    --
    -- The popup was the nvim-driven twin of herdr's prefix+f "floating bash in
    -- focused pane cwd", and is sized to match. It is one popup per line, and
    -- that is forced by herdr rather than chosen: a popup pane has no pane_id in
    -- the socket API — plugin.pane.open answers {"type":"ok"} with no payload,
    -- and the pane is in neither pane.list nor session.snapshot — so there is
    -- nothing to send a second line to. The command travels in the env map at
    -- open time instead, the same route popup.sh uses for its content.
    --
    -- Consequences of popup mode, worth knowing at the keyboard:
    --   * the popup is focused (an unfocused one is not even the current popup
    --     and its process does not survive), so Åpp takes you out of nvim
    --   * shell state does not carry between two Åpp presses; the popup drops
    --     into an interactive bash after the command, so continue in there
    --   * ctrl-d closes it and returns you to nvim
    --   * it needs local.f-herdr linked — :HerdrPluginLink — because a popup can
    --     only be opened through a registered plugin entrypoint
    --
    -- The pane modes have none of those limits: pane.split answers with a real
    -- pane_id, so one pane is created once and every later Åpp is sent into it.
    -- cd, exports and variables therefore persist between lines, which is the
    -- main reason to prefer them. There is deliberately no *remote popup*: for
    -- placement = "popup" herdr refuses workspace_id and target_pane_id, so a
    -- popup always lands over the focused pane of the session it is asked of and
    -- cannot be aimed at a workspace without dragging your view there.

    local function buf_dir()
      local dir = vim.fn.expand("%:p:h")
      return dir ~= "" and dir or vim.fn.getcwd()
    end

    local function popup_bash(fh, cmd)
      return fh.popup_shell({
        cmd = cmd,
        cwd = buf_dir(),
        width = "80%",
        height = "60%",
      })
    end

    -- The one reusable Åpp pane, as a target table.
    --
    -- Kept here rather than in f-herdr's surface registry on purpose: the
    -- registry verifies entries with M.live_panes(), which only ever asks our
    -- own session, so a bashPop in another session could not be checked there.
    -- A target is verified through its own socket instead. :HerdrTargets reports
    -- it; :HerdrSurfaces does not list it.
    local bash_pane = nil

    -- Reuse the pane if it is still the terminal we made, else split a new one.
    -- Closing it by hand is a supported way to get a fresh shell.
    local function bash_pane_target(fh)
      if bash_pane then
        if fh.verify_target(bash_pane) then
          return bash_pane, nil
        end
        bash_pane = nil
      end

      local want = ftarget.bash
      local base
      if want.kind == "remote_pane" then
        base = {
          session = want.session,
          socket = want.socket,
          is_this = want.is_this,
          workspace_id = want.workspace_id,
        }
      else
        local me = fh.this_pane()
        if not me then
          return nil, "cannot tell which workspace this nvim is in"
        end
        base = { is_this = true, workspace_id = me.workspace_id }
      end

      -- Unfocused, so Åpp does not yank you out of nvim the way the popup does.
      -- "down" keeps a wide short shell under whatever is there, which suits
      -- command output better than a narrow column.
      local created, err = fh.split_pane(base, {
        cwd = buf_dir(),
        direction = "down",
        ratio = 0.3,
        focus = false,
      })
      if not created then
        return nil, err
      end

      -- Ours, so tag it: the label is what makes it findable in herdr, and the
      -- tag is what distinguishes our scratch shell from anything already there.
      fh.request(fh.target_socket(created), "pane.rename",
        { pane_id = created.pane_id, label = fh.tagged("bashPop") })

      bash_pane = created
      return bash_pane, nil
    end

    -- Run a line (or nothing) in whichever bash destination is selected.
    local function bash_send(fh, cmd)
      if ftarget.bash.kind == "popup" then
        local _, popup_err = popup_bash(fh, cmd)
        if popup_err then
          return nil, "no popup: " .. tostring(popup_err)
        end
        return true, nil
      end

      local t, err = bash_pane_target(fh)
      if not t then
        return nil, tostring(err)
      end
      if cmd then
        local _, run_err = fh.run_on(t, cmd)
        if run_err then
          return nil, tostring(run_err)
        end
      end
      return t, nil
    end

    -- Åp is for shell buffers: the text under the cursor is a command, and
    -- sending a python line to bash is never what you meant.
    local function is_sh_buffer()
      local file = vim.api.nvim_buf_get_name(0)
      local ft = vim.bo.filetype
      return file:match("%.([^.]+)$") == "sh" or ft == "sh" or ft == "bash"
    end

    local function require_sh()
      if is_sh_buffer() then
        return true
      end
      vim.notify("Åp: this is not a .sh buffer", vim.log.levels.WARN)
      return false
    end

    -- The single entry point behind every Åp binding: gate on the filetype, hand
    -- the text to the selected bash destination, report what went wrong.
    -- text = nil means "open it, run nothing", which is what Åpo wants.
    -- Returns (target, client) so a caller can go on to focus it.
    local function bash_run(text, o)
      o = o or {}
      if not o.any_filetype and not require_sh() then
        return nil
      end
      if text ~= nil and vim.trim(text) == "" then
        vim.notify("Åp: nothing to run", vim.log.levels.WARN)
        return nil
      end

      local fh, herdr_err = herdr()
      if not fh then
        vim.notify("herdr: " .. herdr_err, vim.log.levels.ERROR)
        return nil
      end

      local t, err = bash_send(fh, text)
      if err then
        vim.notify("herdr: " .. err, vim.log.levels.ERROR)
        return nil
      end
      return t, fh
    end

    -- Operator function for Åp + motion, the twin of herdr_send_operator. Being
    -- an operator is what buys the whole grammar for free: treesitter text
    -- objects (Åpif, Åpac, Åpal), flash (Åpä to a jump label, ÅpÄ), the
    -- repeatable f/F/t/T, and anything else mapped in operator-pending mode.
    _G.herdr_bash_operator = function(type)
      local start_pos = vim.api.nvim_buf_get_mark(0, '[')
      local end_pos = vim.api.nvim_buf_get_mark(0, ']')
      local lines = vim.api.nvim_buf_get_lines(0, start_pos[1] - 1, end_pos[1], false)

      if #lines > 0 and type == 'char' then
        lines[#lines] = string.sub(lines[#lines], 1, end_pos[2] + 1)
        lines[1] = string.sub(lines[1], start_pos[2] + 1)
      end
      bash_run(table.concat(lines, "\n"))
    end

    -- ------------------------------------------------------------------
    -- Åp grammar — the same shape as Ås, bash instead of the REPL
    -- ------------------------------------------------------------------
    --
    --   Åp<motion>  run a motion or text object
    --   Åp (visual) run the selection
    --   Åps         run the current line
    --   Åpp         the same, kept because fingers know it
    --   Åpb         run the block (vip)
    --   Åpf         run the whole file's contents
    --   Åpo         open/focus the bash, run nothing
    --
    -- Åp is both a prefix and an operator, exactly as Ås is: nvim waits
    -- timeoutlen to see whether a p/s/b/f/o follows, and treats anything else as
    -- the start of a motion. The five explicit maps do shadow those letters as
    -- motions after Åp — f{char} is the only real loss, the same one Åsf already
    -- accepts. s costs nothing here because flash.nvim disables s in
    -- operator-pending mode, and p/b/o are not motions to begin with.

    -- [Åp] + motion / text object
    map("n", "Åp", function()
      if not is_sh_buffer() then
        -- Deferred: an expr mapping is evaluated under textlock, where notifying
        -- immediately is not safe.
        vim.schedule(function()
          vim.notify("Åp: this is not a .sh buffer", vim.log.levels.WARN)
        end)
        return ""
      end
      vim.go.operatorfunc = "v:lua.herdr_bash_operator"
      return "g@"
    end, vim.tbl_extend("force", opts, { expr = true, desc = "Run motion in bash" }))

    -- [Åp] VISUAL SELECTION
    map("x", "Åp", function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)
      vim.schedule(function() bash_run(get_visual_selection()) end)
    end, vim.tbl_extend("force", opts, { desc = "Run selection in bash" }))

    -- [Åps] / [Åpp] CURRENT LINE. Åpp is an alias: it is what this used to be
    -- called, and Åps is the name that matches Åss.
    local function bash_line()
      bash_run(vim.api.nvim_get_current_line())
    end
    map("n", "Åps", bash_line, vim.tbl_extend("force", opts, { desc = "Run line in bash" }))
    map("n", "Åpp", bash_line, vim.tbl_extend("force", opts, { desc = "Run line in bash (alias of Åps)" }))

    -- [Åpb] BLOCK (paragraph under the cursor)
    map("n", "Åpb", function()
      if not require_sh() then return end
      vim.cmd("normal! vip")
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', false)
      vim.schedule(function() bash_run(get_visual_selection()) end)
    end, vim.tbl_extend("force", opts, { desc = "Run block in bash" }))

    -- [Åpf] WHOLE FILE — its contents, pasted, not `bash <file>`. Pasting is what
    -- keeps the pane's shell state: a cd or an export in the file still applies
    -- afterwards, which running it as a subprocess would throw away.
    map("n", "Åpf", function()
      bash_run(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
    end, vim.tbl_extend("force", opts, { desc = "Run whole file in bash" }))

    -- [Åpo] OPEN, run nothing. Deliberately allowed from any filetype — "give me
    -- a shell here" is useful from a .py buffer too — and it focuses, because
    -- that is the point of asking for it. A popup focuses itself and has no
    -- target to focus.
    map("n", "Åpo", function()
      local t, fh = bash_run(nil, { any_filetype = true })
      if type(t) == "table" and fh then
        fh.focus_target(t)
      end
    end, vim.tbl_extend("force", opts, { desc = "Open/focus the bash (Åä picks popup/pane)" }))

    -- :HerdrTargets — all three destinations and whether they are still there.
    -- Cheaper to read than three separate failures at the keyboard.
    vim.api.nvim_create_user_command("HerdrTargets", function()
      local lines = { { "=== f-herdr targets ===\n", "Title" } }
      for _, l in ipairs(ftarget.lines()) do
        table.insert(lines, { l .. "\n" })
      end
      local fh = herdr()
      if fh and bash_pane then
        local pane = fh.verify_target(bash_pane)
        table.insert(lines, { string.format("\nÅpp pane  %s %s\n",
          fh.target_label(bash_pane), pane and "live" or "DEAD (next Åpp re-splits)") })
      end
      vim.api.nvim_echo(lines, true, {})
    end, { desc = "herdr: show the REPL / visidata / Åpp targets and their liveness" })

    -- Terminal Nav
    map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = "Iron: Exit Term Mode" })
    map('t', '<M-Left>',  '<C-\\><C-n><C-w>h', { desc = "Jump Left" })
    map('t', '<M-Down>',  '<C-\\><C-n><C-w>j', { desc = "Jump Down" })
    map('t', '<M-Up>',    '<C-\\><C-n><C-w>k', { desc = "Jump Up" })
    map('t', '<M-Right>', '<C-\\><C-n><C-w>l', { desc = "Jump Right" })
  end,
}
