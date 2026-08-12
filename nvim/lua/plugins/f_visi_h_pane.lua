-- f_visi_h_pane: put the variable under the cursor into visidata, via herdr.
--
-- The herdr port of visi_tmux_pane.lua (kept as visi_tmux_pane.lua.bak). Same
-- gesture, same result:
--
--   Åv   with the cursor on a name in a .py buffer
--        -> export that object to <cwd>/<name>_NNN.csv from the live python REPL
--        -> open it in visidata, in a new herdr tab
--        -> Enter in that tab deletes the csv and closes the tab
--
--   :FVisiHPane[!] [expr]   same thing; ! opens the tab unfocused, and an
--                           explicit expression beats the word under the cursor
--                           (so :FVisiHPane df.head(20) works)
--   :FVisiHPaneCheck        dry run: what would it use for the REPL and for vd
--
-- What changed in the port, and why:
--
--   * tmux new-window        -> f_herdr.new_tab. The tab is created through the
--     herdr socket, so it is tagged and registered in f-herdr's surface
--     registry, and is addressable afterwards as :HerdrRun <name> ...
--
--   * window named "ipyOut"  -> pane.process_info. tmux could only be asked
--     "is there a window with this name"; herdr can be asked what is actually
--     running in a pane, so the fallback REPL is found by looking for a python
--     process rather than by trusting a name convention.
--
--   * `. ./.venv/bin/activate; vd` -> the absolute path of vd, from the venv
--     f_venv finds by walking up from *this buffer* rather than from nvim's
--     cwd, so a file opened from another project still gets that project's
--     visidata. Resolved before anything is exported, so a missing visidata is
--     a message instead of an error inside a tab already waiting on a csv.
--
--   * the export line now imports the helper module itself. The tmux version
--     called f_visi_nvim_tool.export_to_csv() and relied on the name already
--     being imported in the REPL; here the buffer's directory is put on
--     sys.path and the module imported as part of the same line.
--
-- Needs f-herdr.lua loaded (it owns the socket client, on _G.f_herdr) and a
-- python REPL to export from: iron's, or any python running in a herdr pane in
-- this workspace.

return {
  -- Two rules for a local spec's `dir`, the second learned the hard way:
  --
  --   1. No other spec may claim it. lazy.nvim dedupes by dir, so sharing one
  --      means a spec silently never loads. f-herdr claims lua; the config
  --      root was visi_tmux_pane's.
  --
  --   2. It must not contain a file called lazy.lua. lazy.nvim's pkg loader
  --      (lua/lazy/pkg/lazy.lua: M.lazy_file = "lazy.lua") reads <dir>/lazy.lua
  --      as this plugin's spec and executes it. This spec used to say
  --      lua/config, which is where the bootstrap lazy.lua lives — so lazy ran
  --      the bootstrap a second time from inside its own setup(). Where the
  --      plugins were already installed that passed unnoticed; on a fresh
  --      machine it re-entered setup() before anything had been cloned and
  --      died on the first require of a missing plugin, surfacing as
  --      "Re-sourcing your config is not supported" and an E5113 loop error
  --      about config.keymaps.
  --
  -- lua/plugins satisfies both: no lazy.lua, pkg.json or rockspec in it, and
  -- nothing else claims it now that f-hello is gone.
  dir = vim.fn.stdpath("config") .. "/lua/plugins",
  name = "f_visi_h_pane",
  lazy = false,
  config = function()
    -- Where this file lives, hence where the helper module is copied from.
    local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
    local source_py = script_dir .. "/f_visi_nvim_tool.py"

    -- Shared with iron.lua, so vd comes from the same venv as the REPL that
    -- wrote the csv.
    local fvenv = require("f_venv")

    local function echo(msg, hl)
      vim.api.nvim_echo({ { msg, hl or "Normal" } }, true, {})
    end

    math.randomseed(os.time() + (vim.fn.getpid and vim.fn.getpid() or 0))
    local function rand3()
      return string.format("%03d", math.random(0, 999))
    end

    -- Python string literal from a lua string. Only paths go through here, but
    -- they still get escaped rather than trusted.
    local function pyquote(s)
      return '"' .. (tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"')) .. '"'
    end

    ---------------------------------------------------------------------------
    -- the three things this needs: f-herdr, a python REPL, vd
    ---------------------------------------------------------------------------

    -- f-herdr's client, looked up at press time rather than at config time:
    -- both plugins are lazy = false and their load order is not guaranteed.
    -- Returns (client, nil) or (nil, reason).
    local function herdr()
      local fh = _G.f_herdr
      if type(fh) ~= "table" or type(fh.call) ~= "function" then
        return nil, "f-herdr is not loaded (_G.f_herdr is missing) — see :Lazy for f_herdr"
      end
      local path, err = fh.socket_path()
      if not path then
        return nil, err
      end
      return fh, nil
    end

    -- iron's python REPL, if it has one and it is on screen. Lifted from
    -- visi_tmux_pane.lua unchanged: iron.get is the documented way in, and the
    -- buffer scan is the fallback for iron versions that do not have it.
    local function check_iron_python_repl()
      local ok, iron = pcall(require, "iron.core")
      if not ok then
        return { running = false, visible = false, info = "iron.core not available" }
      end

      local bufnr
      local meta
      local got = pcall(function() meta = iron.get("python") end)
      if got and type(meta) == "table" and meta.bufnr and vim.api.nvim_buf_is_valid(meta.bufnr) then
        bufnr = meta.bufnr
      else
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(b) then
            local name = vim.api.nvim_buf_get_name(b)
            local ft_ok, ft = pcall(vim.api.nvim_get_option_value, "filetype", { buf = b })
            if (ft_ok and ft == "iron") or name:match("iron://") then
              bufnr = b
              break
            end
          end
        end
      end

      if not bufnr then
        return { running = false, visible = false, info = "no iron python REPL buffer" }
      end

      local wins = vim.fn.win_findbuf(bufnr) or {}
      return {
        running = true,
        visible = #wins > 0,
        info = string.format("bufnr=%d wins=%d", bufnr, #wins),
      }
    end

    -- A python REPL living in a herdr pane. This is what replaces "is there a
    -- tmux window called ipyOut": pane.process_info reports the foreground
    -- processes of a pane, so the question asked is what is actually running.
    --
    -- Scored rather than first-match, because "python" in the process name is
    -- also true of a script that merely happens to be running. An ipython in
    -- the cmdline is the strong signal; a bare python process is the weak one.
    -- Scoped to our own workspace, so a REPL in someone else's workspace is
    -- never typed into.
    --
    -- Returns (pane, description) or (nil, reason).
    local function find_herdr_python_pane(fh)
      local result, err = fh.call("pane.list")
      if not result then
        return nil, err
      end

      local me = fh.this_pane()
      local my_workspace = me and me.workspace_id
      local my_pane = vim.env.HERDR_PANE_ID

      local best, best_score, best_why
      for _, p in ipairs(result.panes or {}) do
        if p.pane_id ~= my_pane and (not my_workspace or p.workspace_id == my_workspace) then
          local info = fh.call("pane.process_info", { pane_id = p.pane_id })
          local procs = info and info.process_info and info.process_info.foreground_processes or {}
          for _, proc in ipairs(procs) do
            local name = (proc.name or ""):lower()
            local cmdline = (proc.cmdline or ""):lower()
            local score, why
            if cmdline:find("ipython", 1, true) then
              score, why = 2, "ipython"
            elseif name:match("^i?python[%d.]*$") then
              score, why = 1, name
            end
            if score and score > (best_score or 0) then
              best, best_score, best_why = p, score, why
            end
          end
        end
      end

      if not best then
        return nil, "no python process found in any pane of this workspace"
      end
      return best, string.format("%s running %s", best.pane_id, best_why)
    end

    -- visidata, as an absolute path out of the buffer's own venv (see f_venv:
    -- the anchor is the buffer, not nvim's cwd). Running <venv>/bin/vd directly
    -- is enough — its shebang points at that venv's python — so the tab does
    -- not have to source an activate script that may not be there.
    local function find_vd()
      return fvenv.exe("vd", 0)
    end

    -- Put f_visi_nvim_tool.py next to the buffer if it is not there already, so
    -- the REPL can import it. fs_copyfile rather than a `cp` shell-out: no
    -- filename ever becomes a shell word.
    local function ensure_tool(buf_dir)
      local target = buf_dir .. "/f_visi_nvim_tool.py"
      if vim.fn.filereadable(target) == 1 then
        return target, false, nil
      end
      if vim.fn.filereadable(source_py) == 0 then
        return nil, false, "source missing: " .. source_py
      end
      local ok, err = (vim.uv or vim.loop).fs_copyfile(source_py, target)
      if not ok then
        return nil, false, string.format("copy failed: %s -> %s (%s)", source_py, target, tostring(err))
      end
      return target, true, nil
    end

    ---------------------------------------------------------------------------
    -- the gesture
    ---------------------------------------------------------------------------

    -- opts = { expr = <python expression>, focus = <focus the new tab> }
    local function visi(opts)
      opts = opts or {}

      local file = vim.api.nvim_buf_get_name(0)
      if file:match("%.([^.]+)$") ~= "py" then
        echo("needs to be .py", "WarningMsg")
        return
      end

      local expr = opts.expr
      if not expr or expr == "" then
        expr = vim.fn.expand("<cword>")
      end
      if expr == "" then
        echo("no word under cursor", "WarningMsg")
        return
      end

      local fh, herdr_err = herdr()
      if not fh then
        echo("herdr: " .. herdr_err, "ErrorMsg")
        return
      end

      local cwd = vim.fn.getcwd()

      -- Resolved before anything is created or exported: the whole point of a
      -- csv is the viewer, so no viewer means no work.
      local vd = find_vd()
      if not vd then
        echo("visidata (vd) not found in this buffer's venv (" .. tostring(fvenv.venv(0)) .. ") or on $PATH", "ErrorMsg")
        return
      end

      local buf_dir = vim.fn.fnamemodify(file, ":h")
      local _, copied, tool_err = ensure_tool(buf_dir)
      if tool_err then
        echo(tool_err, "ErrorMsg")
        return
      end
      if copied then
        echo("copied f_visi_nvim_tool.py -> " .. buf_dir, "MoreMsg")
      end

      -- Pick the REPL: iron if it is up and on screen, otherwise a python
      -- process in one of this workspace's herdr panes.
      local iron = check_iron_python_repl()
      local target, target_info, repl_pane
      if iron.running and iron.visible then
        target, target_info = "iron", iron.info
      else
        local pane, why = find_herdr_python_pane(fh)
        if not pane then
          echo("no target: iron REPL not visible, and " .. why, "WarningMsg")
          return
        end
        target, target_info, repl_pane = "herdr", why, pane
      end

      -- Tab label and csv name. The expression can be anything python accepts,
      -- so the filename is derived from a scrubbed copy of it rather than from
      -- the expression itself.
      local stem = expr:gsub("[^%w_]", "_"):gsub("^_+", ""):sub(1, 24)
      if stem == "" then
        stem = "expr"
      end
      local name, csv_abs
      repeat
        name = stem .. "_" .. rand3()
        csv_abs = cwd .. "/" .. name .. ".csv"
      until vim.fn.filereadable(csv_abs) == 0 and not fh.surfaces[name]

      local rec, tab_err = fh.new_tab({
        label = name,
        name = name,
        focus = opts.focus ~= false,
        cwd = cwd,
      })
      if not rec then
        echo("herdr: could not create tab: " .. tostring(tab_err), "ErrorMsg")
        return
      end

      -- One line, so it survives being pasted into a REPL that reindents
      -- blocks: make the buffer's directory importable, import the helper,
      -- write the csv.
      local code = string.format(
        '_f_visi_dir = %s; import sys; (_f_visi_dir in sys.path) or sys.path.insert(0, _f_visi_dir);'
        .. ' import f_visi_nvim_tool; f_visi_nvim_tool.export_to_csv(%s, %s)',
        pyquote(buf_dir), expr, pyquote(csv_abs))

      echo("=== f_visi_h_pane ===", "Title")
      echo("expr        " .. expr)
      echo("repl        " .. target .. "  (" .. tostring(target_info) .. ")")
      echo("tab         " .. rec.name .. "  " .. tostring(rec.tab_id), "MoreMsg")
      echo("csv         " .. csv_abs, "MoreMsg")
      echo("vd          " .. vd)

      local sent_err
      if target == "iron" then
        local ok, iron_core = pcall(require, "iron.core")
        if ok then
          iron_core.send("python", code)
        else
          sent_err = "iron.core disappeared between check and send"
        end
      else
        -- f-herdr's run(): wait for a prompt, paste, wait for the echo, then a
        -- real Enter key. A trailing "\n" in the text would be inserted
        -- literally by the line editor instead of submitting the line.
        local _, run_err = fh.run(repl_pane.pane_id, code)
        sent_err = run_err
      end
      if sent_err then
        echo("export send failed: " .. tostring(sent_err), "ErrorMsg")
        return
      end

      -- The tab waits for the csv rather than being told when it lands: the
      -- REPL is the only thing that knows when the write finished, and it has
      -- no way to report back. "\\n" is passed through to printf, which turns
      -- it into a newline — a real newline here would be pasted as one.
      local q = vim.fn.shellescape(csv_abs)
      local shell_cmd = string.format(
        "until [ -f %s ]; do sleep 0.2; done && %s %s;"
        .. " printf '\\nPress Enter to delete the csv and close this tab...'; read -r _; rm -f %s; exit",
        q, vim.fn.shellescape(vd), q, q)

      local _, cmd_err = fh.run(rec.name, shell_cmd)
      if cmd_err then
        echo("herdr: could not start vd in " .. rec.name .. ": " .. tostring(cmd_err), "ErrorMsg")
      end
    end

    ---------------------------------------------------------------------------
    -- entry points
    ---------------------------------------------------------------------------

    vim.keymap.set("n", "Åv", function()
      visi({})
    end, { noremap = true, silent = false, desc = "visi: export <cword> to CSV and open in vd (herdr tab)" })

    -- :FVisiHPane [expr]   bang opens the tab without switching to it
    vim.api.nvim_create_user_command("FVisiHPane", function(o)
      visi({ expr = o.args ~= "" and o.args or nil, focus = not o.bang })
    end, { nargs = "*", bang = true, desc = "visi: export an expression to CSV and open it in vd (herdr tab)" })

    -- Everything the gesture depends on, without exporting anything. Cheaper to
    -- read than three separate failures.
    vim.api.nvim_create_user_command("FVisiHPaneCheck", function()
      local lines = { { "=== f_visi_h_pane check ===\n", "Title" } }
      local function add(label, value, hl)
        table.insert(lines, { string.format("%-10s %s\n", label, value), hl })
      end

      local cwd = vim.fn.getcwd()
      add("buffer", vim.api.nvim_buf_get_name(0) ~= "" and vim.fn.expand("%:t") or "<no name>")
      add("cword", vim.fn.expand("<cword>"))
      add("cwd", cwd)

      -- Which venv, and how it was found: "$VIRTUAL_ENV" or "cwd" here rather
      -- than "buffer" is usually the answer to "why that python".
      local venv, how = fvenv.venv(0)
      add("anchor", fvenv.anchor(0))
      add("venv", venv and (venv .. "  (via " .. how .. ")") or "none", venv and "DiagnosticOk" or "WarningMsg")

      local vd = find_vd()
      add("vd", vd or "NOT FOUND", vd and "DiagnosticOk" or "ErrorMsg")

      local fh, herdr_err = herdr()
      if not fh then
        add("herdr", "DOWN — " .. herdr_err, "ErrorMsg")
        vim.api.nvim_echo(lines, true, {})
        return
      end
      add("herdr", "up", "DiagnosticOk")

      local iron = check_iron_python_repl()
      add("iron", string.format("running=%s visible=%s (%s)",
        tostring(iron.running), tostring(iron.visible), iron.info))

      local pane, why = find_herdr_python_pane(fh)
      add("herdr repl", pane and why or ("none — " .. tostring(why)), pane and "DiagnosticOk" or nil)

      local chosen = (iron.running and iron.visible) and "iron"
        or (pane and ("herdr pane " .. pane.pane_id) or "NONE")
      add("would use", chosen, chosen == "NONE" and "ErrorMsg" or "MoreMsg")

      vim.api.nvim_echo(lines, true, {})
    end, { desc = "visi: report the REPL and vd this would use, without exporting" })

    vim.g.f_visi_h_pane = "loaded (config ran)"
  end,
}
