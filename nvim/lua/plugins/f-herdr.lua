-- f-herdr: minimal nvim <-> herdr client, talking straight to the control socket.
--
-- herdr speaks newline-delimited JSON over a unix socket: one request object per
-- line, one response object per line. The socket path is injected as
-- HERDR_SOCKET_PATH into every herdr-managed pane, so this works whenever nvim
-- was launched from inside herdr. No CLI shell-out.
--
--   request   {"id":"nvim", "method":"pane.get", "params":{"pane_id":"w6:p1"}}
--   response  {"id":"nvim", "result":{...}}   or   {"id":"nvim", "error":{code,message}}
--
-- Steps a/b/c/d/e of the build-out:
--   :HerdrCheck                      is the socket up and the plugin linked?
--   :HerdrEnding                     (a) file ending / filetype of this buffer
--   :HerdrWhere                      (b) which pane, tab, workspace, cwd we are in
--   :HerdrPopup                      (c) report in an nvim floating window
--   :HerdrPopupPane                  (c) report in a real herdr popup pane
--   :HerdrPopupShell [cmd]           (c) herdr popup running a shell
--   :HerdrPopupClose                 (c) close the current herdr popup
--   :HerdrTab[!] [label]             (d) new tab in this workspace; ! = focus it
--   :HerdrRun <target> <cmd...>      (e) run a command in a surface
--   :HerdrType <target> <text...>    (e) literal paste, no Enter
--   :HerdrSend <target> <key...>     (e) real key presses, e.g. ctrl+c Enter
--   :HerdrRead <target>              read a surface's visible output back
--   :HerdrRename <target> <label>    set the label herdr displays
--   :HerdrSurfaces                   list what we created, by name
--   :HerdrPluginLink / :HerdrPluginList   register nvim as a herdr plugin
--   :HerdrCall <method> [json]       raw escape hatch, e.g. :HerdrCall pane.list
--
-- A <target> is a name from :HerdrSurfaces ("build", "popup2"), the label the
-- surface shows in herdr, a raw pane id ("w6:p3"), or a raw tab id ("w6:t2",
-- resolved to that tab's focused pane). Other plugins should hold the *name*:
-- it survives across calls and is what M.get(name) takes.
--
-- Identity and ownership both hang off terminal_id, not pane id. A pane id
-- ("w6:p1") names a slot and can be reissued after that pane closes; a
-- terminal_id ("term_658be6...") is minted per terminal and never reused. Every
-- surface we create is labelled with our own owner tag, "[fh:<6 hex of this
-- nvim's terminal_id>]", so a second nvim in a second workspace runs the same
-- plugin without either one claiming the other's tabs.
--
-- Everything is also on _G.f_herdr for poking at from :lua.

vim.g.f_herdr_spec = "loaded (spec read)"

return {
  -- IMPORTANT: a `dir` that no other local spec uses. The previous version of
  -- this file claimed dir = stdpath("config"), the same dir as
  -- visi_tmux_pane.lua, and never loaded.
  --
  -- Equally important, and less obvious: never point a `dir` at a directory
  -- containing a file called lazy.lua. lazy.nvim reads <dir>/lazy.lua as the
  -- plugin's spec and runs it, so aiming a spec at lua/config re-executes the
  -- bootstrap from inside setup() (see the long note in f_visi_h_pane.lua).
  -- lua/ is safe only for as long as lua/lazy.lua does not exist.
  dir = vim.fn.stdpath("config") .. "/lua",
  name = "f_herdr",
  lazy = false,
  config = function()
    local TIMEOUT_MS = 2000

    local M = {}

    ---------------------------------------------------------------------------
    -- socket transport
    ---------------------------------------------------------------------------

    -- Cheap, no-I/O check: is there a socket to talk to at all?
    -- Returns (path, nil) or (nil, reason).
    function M.socket_path()
      local path = vim.env.HERDR_SOCKET_PATH
      if not path or path == "" then
        return nil, "HERDR_SOCKET_PATH is not set — nvim was not launched inside herdr"
      end
      if not (vim.uv or vim.loop).fs_stat(path) then
        return nil, "socket file does not exist (herdr not running?): " .. path
      end
      return path, nil
    end

    -- One request, one response, blocking. Returns (result, nil) or (nil, err).
    function M.call(method, params, timeout_ms)
      local path, err = M.socket_path()
      if not path then
        return nil, err
      end

      local buf = ""
      local ok, chan = pcall(vim.fn.sockconnect, "pipe", path, {
        on_data = function(_, data)
          -- nvim splits the stream on newlines and strips them; rejoining
          -- restores the bytes, including the newline that frames a reply.
          buf = buf .. table.concat(data, "\n")
        end,
      })
      if not ok or chan == 0 then
        return nil, "cannot connect to herdr socket: " .. path
      end

      local payload = vim.json.encode({
        id = "nvim",
        method = method,
        params = params or vim.empty_dict(),
      })
      if not pcall(vim.fn.chansend, chan, payload .. "\n") then
        pcall(vim.fn.chanclose, chan)
        return nil, "failed to write request to herdr socket"
      end

      local got = vim.wait(timeout_ms or TIMEOUT_MS, function()
        return buf:find("\n", 1, true) ~= nil
      end, 10)
      pcall(vim.fn.chanclose, chan)

      if not got then
        return nil, "timed out waiting for herdr response to " .. method
      end

      local decoded
      ok, decoded = pcall(vim.json.decode, buf:match("^[^\n]*"))
      if not ok or type(decoded) ~= "table" then
        return nil, "malformed response from herdr: " .. buf:sub(1, 200)
      end
      if decoded.error then
        return nil, string.format("herdr error %s: %s", decoded.error.code, decoded.error.message)
      end
      return decoded.result, nil
    end

    ---------------------------------------------------------------------------
    -- (a) file ending
    ---------------------------------------------------------------------------

    -- Returns a table describing the buffer's name and its ending. `ending` is
    -- the extension without the dot, or nil for an unnamed or extensionless
    -- buffer. `filetype` is nvim's own detection, which is the thing you
    -- usually want to branch on — ".ts" vs filetype "typescript".
    function M.file_ending(bufnr)
      bufnr = bufnr or 0
      local path = vim.api.nvim_buf_get_name(bufnr)
      local tail = vim.fn.fnamemodify(path, ":t")
      return {
        path = path ~= "" and path or nil,
        name = tail ~= "" and tail or nil,
        ending = tail:match("%.([%w_%-]+)$"),
        filetype = vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or nil,
      }
    end

    ---------------------------------------------------------------------------
    -- (b) where am I: pane / tab / workspace / cwd
    ---------------------------------------------------------------------------

    -- Resolve our own pane. HERDR_PANE_ID is injected into the pane's shell, so
    -- it is the truthful answer for "the pane nvim is running in". pane.current
    -- is the fallback for the case where nvim was started some other way — it
    -- answers with the focused pane, which is usually but not always us.
    function M.this_pane()
      local pane_id = vim.env.HERDR_PANE_ID
      if pane_id and pane_id ~= "" then
        local result, err = M.call("pane.get", { pane_id = pane_id })
        if result then
          return result.pane, "HERDR_PANE_ID"
        end
        return nil, nil, err
      end

      local result, err = M.call("pane.current")
      if result then
        return result.pane, "pane.current (focused)"
      end
      return nil, nil, err
    end

    -- Gather the full picture in one go. Never throws: each piece that fails
    -- lands in ctx.errors and the rest is still returned, so a partial answer
    -- is still a useful answer while debugging.
    function M.context()
      local ctx = {
        errors = {},
        env = {
          socket = vim.env.HERDR_SOCKET_PATH,
          pane_id = vim.env.HERDR_PANE_ID,
          tab_id = vim.env.HERDR_TAB_ID,
          workspace_id = vim.env.HERDR_WORKSPACE_ID,
        },
        nvim = {
          cwd = vim.fn.getcwd(),
          file = M.file_ending(0),
        },
      }

      local pane, source, err = M.this_pane()
      if not pane then
        table.insert(ctx.errors, "pane: " .. tostring(err))
        return ctx
      end
      ctx.pane, ctx.pane_source = pane, source

      local tab, tab_err = M.call("tab.get", { tab_id = pane.tab_id })
      if tab then
        ctx.tab = tab.tab
      else
        table.insert(ctx.errors, "tab: " .. tostring(tab_err))
      end

      local ws, ws_err = M.call("workspace.get", { workspace_id = pane.workspace_id })
      if ws then
        ctx.workspace = ws.workspace
      else
        table.insert(ctx.errors, "workspace: " .. tostring(ws_err))
      end

      return ctx
    end

    -- Flatten a context into printable "label  value" lines.
    function M.context_lines()
      local ctx = M.context()
      local out = {}
      local function add(fmt, ...)
        table.insert(out, string.format(fmt, ...))
      end

      local f = ctx.nvim.file
      add("buffer      %s", f.name or "<no name>")
      add("ending      %s", f.ending or "<none>")
      add("filetype    %s", f.filetype or "<none>")
      add("nvim cwd    %s", ctx.nvim.cwd)
      add("")

      if ctx.pane then
        add("pane        %s   (via %s)", ctx.pane.pane_id, ctx.pane_source)
        add("pane cwd    %s", ctx.pane.cwd or "-")
        add("foreground  %s", ctx.pane.foreground_cwd or "-")
        add("focused     %s", tostring(ctx.pane.focused))
        add("agent       %s (%s)", ctx.pane.agent or "-", ctx.pane.agent_status or "-")
        add("terminal    %s", ctx.pane.terminal_id or "-")
      end
      if ctx.tab then
        add("tab         %s   #%s %q  panes=%s",
          ctx.tab.tab_id, tostring(ctx.tab.number), ctx.tab.label or "", tostring(ctx.tab.pane_count))
      end
      if ctx.workspace then
        add("workspace   %s   #%s %q  tabs=%s panes=%s",
          ctx.workspace.workspace_id, tostring(ctx.workspace.number), ctx.workspace.label or "",
          tostring(ctx.workspace.tab_count), tostring(ctx.workspace.pane_count))
      end

      if #ctx.errors > 0 then
        add("")
        for _, e in ipairs(ctx.errors) do
          add("ERROR       %s", e)
        end
      end
      return out, ctx
    end

    ---------------------------------------------------------------------------
    -- (c) popup
    ---------------------------------------------------------------------------

    -- A plain nvim floating window. Sizes itself to the content, closes on q or
    -- <Esc>. Returns (win, buf) so callers can decorate it further.
    --
    -- NOTE: this is an *nvim* popup, not a herdr popup. herdr popups exist
    -- (placement = "popup") but the socket API only opens them via
    -- plugin.pane.open, which requires a registered plugin_id + entrypoint —
    -- i.e. nvim would have to be installed as a herdr plugin first. Separate
    -- step; popup.close is the only popup verb reachable from here today.
    function M.popup(lines, opts)
      opts = opts or {}
      lines = lines or {}

      local width = opts.width or 0
      for _, l in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(l))
      end
      width = math.min(math.max(width + 2, 20), vim.o.columns - 4)
      local height = math.min(math.max(#lines, 1), vim.o.lines - 6)

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].bufhidden = "wipe"

      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        row = math.max(math.floor((vim.o.lines - height) / 2) - 1, 0),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = opts.title or " f-herdr ",
        title_pos = "center",
      })
      vim.wo[win].wrap = false

      for _, key in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", key, function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end, { buffer = buf, nowait = true, silent = true })
      end

      return win, buf
    end

    ---------------------------------------------------------------------------
    -- (c) herdr-native popup, via the plugin entry point
    ---------------------------------------------------------------------------

    -- Must match `id` in f-herdr-plugin/herdr-plugin.toml, and the panes' `id`s.
    M.plugin_id = "local.f-herdr"
    M.plugin_entrypoint = "popup" -- text popup
    M.plugin_shell_entrypoint = "shell" -- popup running a shell
    M.plugin_dir = vim.fn.stdpath("config") .. "/f-herdr-plugin"

    -- Is our manifest registered with the running herdr?
    -- Returns (info, nil) when linked, (nil, nil) when simply absent,
    -- (nil, err) when we could not find out.
    function M.plugin_info()
      local result, err = M.call("plugin.list")
      if not result then
        return nil, err
      end
      for _, p in ipairs(result.plugins or {}) do
        if p.plugin_id == M.plugin_id then
          return p, nil
        end
      end
      return nil, nil
    end

    -- Register the manifest with herdr. This writes an entry into herdr's
    -- plugins.json, so it is deliberately explicit — never called on startup.
    function M.plugin_link()
      if not (vim.uv or vim.loop).fs_stat(M.plugin_dir .. "/herdr-plugin.toml") then
        return nil, "no manifest at " .. M.plugin_dir .. "/herdr-plugin.toml"
      end
      return M.call("plugin.link", { path = M.plugin_dir, enabled = true })
    end

    -- Open a herdr popup pane showing `lines`.
    --
    -- The text goes to a temp file and only its *path* is handed to the popup
    -- process, via the per-open env map. Nothing from a buffer is ever
    -- interpolated into a shell word — see popup.sh.
    function M.popup_pane(lines, opts)
      opts = opts or {}

      -- writefile signals failure with -1 rather than by throwing, so check both.
      local path = vim.fn.tempname()
      local ok, rc = pcall(vim.fn.writefile, lines or {}, path)
      if not ok or rc ~= 0 then
        return nil, "could not write popup content to " .. path .. ": " .. tostring(rc)
      end

      -- Targeting fields are placement-specific, and herdr rejects the wrong
      -- ones outright rather than ignoring them. From its own messages:
      --   popup, overlay  -> target the active pane; send NO target at all
      --   tab             -> workspace_id only
      --   split, zoomed   -> target_pane_id (an existing pane)
      -- and width/height are accepted only for popup. So: no workspace_id, no
      -- target_pane_id, no direction here.
      local params = {
        plugin_id = M.plugin_id,
        entrypoint = M.plugin_entrypoint,
        placement = "popup",
        focus = true, -- an unfocused popup does not survive; see open_plugin_pane
        env = { F_HERDR_POPUP_FILE = path },
      }
      if opts.width then
        params.width = opts.width
      end
      if opts.height then
        params.height = opts.height
      end

      return M.open_plugin_pane(params, opts)
    end

    ---------------------------------------------------------------------------
    -- (d/e) surfaces: named popups and tabs, and input into them
    ---------------------------------------------------------------------------

    -- Logical name -> surface record, so a popup or tab we made can be handed to
    -- another plugin as a stable string instead of a volatile herdr id.
    --
    --   { name, kind = "popup"|"tab", pane_id, tab_id, workspace_id,
    --     label, entrypoint }
    --
    -- `pane_id` is always the pane input goes to: for a tab that is its root
    -- pane, which is the shell herdr just started there.
    M.surfaces = M.surfaces or {}

    local function auto_name(prefix)
      local n = 1
      while M.surfaces[prefix .. n] do
        n = n + 1
      end
      return prefix .. n
    end

    -- Identity of this nvim: the terminal_id of the pane it runs in.
    --
    -- herdr has two kinds of id, and the difference matters here. A pane id
    -- ("w6:p1") is positional — it describes a slot, and herdr can hand the same
    -- one out again after that pane closes. A terminal_id ("term_658be6...") is
    -- minted per terminal and never reused. So terminal_id is the right handle
    -- for both questions we care about: "is this still the same surface" and
    -- "whose surface is it".
    function M.owner_id()
      if not M._owner_id then
        local pane = M.this_pane()
        M._owner_id = pane and pane.terminal_id or nil
      end
      return M._owner_id
    end

    -- Short, label-friendly form of a terminal id.
    local function short_id(terminal_id)
      return (tostring(terminal_id or ""):gsub("^term_", "")):sub(1, 6)
    end

    -- The trailing marker stamped onto every pane and tab we create, scoped to
    -- this nvim: "[fh:658be6]". Two things fall out of that scoping:
    --
    --   * liveness — id present AND label still tagged. The tag is what stops a
    --     stale record from resolving onto a stranger's pane and typing into it.
    --   * isolation — several nvims, in several herdr workspaces, each stamp
    --     their own tag, so none of them claims another's tabs.
    function M.tag()
      local owner = M.owner_id()
      return "[fh:" .. (owner and short_id(owner) or "?") .. "]"
    end

    function M.tagged(label)
      label = (label and label ~= "") and label or "f-herdr"
      local tag = M.tag()
      if label:find(tag, 1, true) then
        return label
      end
      return label .. " " .. tag
    end

    -- Ours specifically, not "some f-herdr's".
    function M.is_tagged(label)
      return type(label) == "string" and label:find(M.tag(), 1, true) ~= nil
    end

    -- The label without our marker, i.e. what the caller asked for.
    function M.untagged(label)
      return vim.trim((tostring(label or ""):gsub(vim.pesc(M.tag()), "")))
    end

    -- Registry-safe name from a human label: "My Build 2" -> "my-build-2".
    function M.slug(s)
      s = tostring(s or ""):lower():gsub("%s+", "-"):gsub("[^%w%-_]", "")
      return (s:gsub("^%-+", ""):gsub("%-+$", ""))
    end

    -- Register a surface. `ids` is { pane_id, terminal_id, tab_id, workspace_id,
    -- label, entrypoint } — already extracted, because the create calls disagree
    -- about how they report the new surface. Returns the record.
    --
    -- A requested name is slugified and, if taken, suffixed rather than
    -- overwriting the existing entry.
    function M.record(kind, ids, opts)
      opts = opts or {}

      local name = opts.name and M.slug(opts.name) or nil
      if not name or name == "" then
        name = auto_name(kind)
      elseif M.surfaces[name] then
        name = auto_name(name .. "-")
      end

      local rec = {
        kind = kind,
        name = name,
        pane_id = ids.pane_id,
        terminal_id = ids.terminal_id,
        tab_id = ids.tab_id,
        workspace_id = ids.workspace_id,
        label = ids.label,
        entrypoint = ids.entrypoint,
        owner_id = M.owner_id(),
      }
      M.surfaces[rec.name] = rec
      return rec
    end

    -- Look a surface up by registry name, then by the label herdr shows for it
    -- (with or without the tag). So :HerdrRename build works whether "build" was
    -- the name we registered or just the label you gave it.
    function M.find(target)
      if type(target) ~= "string" then
        return nil
      end
      local rec = M.surfaces[target]
      if rec then
        return rec
      end
      for _, r in pairs(M.surfaces) do
        if r.label == target or M.untagged(r.label) == target then
          return r
        end
      end
      return nil
    end

    -- Stamp the tag onto a surface so liveness is checkable afterwards. For a
    -- tab that means both the tab label (what you see on the tab bar) and its
    -- root pane's label (what pane.list can check in one call).
    --
    -- On M rather than a local because the create paths above call it, and a
    -- local declared here would not be in scope up there.
    function M.apply_tag(rec, label)
      local want = M.tagged(label or rec.name)
      local err
      if rec.kind == "tab" and rec.tab_id then
        local _, e = M.call("tab.rename", { tab_id = rec.tab_id, label = want })
        err = err or e
      end
      if rec.pane_id then
        local _, e = M.call("pane.rename", { pane_id = rec.pane_id, label = want })
        err = err or e
      end
      rec.label = want
      return want, err
    end

    -- Every live pane, keyed by id. One call answers liveness for both kinds,
    -- which is why tabs get their root pane tagged too. On M for the same
    -- scoping reason as apply_tag.
    function M.live_panes()
      local result, err = M.call("pane.list")
      if not result then
        return nil, err
      end
      local by_id = {}
      for _, p in ipairs(result.panes or {}) do
        by_id[p.pane_id] = p
      end
      return by_id, nil
    end

    -- Is this pane still the exact terminal we recorded, and still ours?
    -- terminal_id settles the first question (a pane id can be reissued, a
    -- terminal id cannot); our owner-scoped tag settles the second.
    local function still_ours(p, rec)
      if not p or not M.is_tagged(p.label) then
        return false
      end
      if rec.terminal_id and p.terminal_id and p.terminal_id ~= rec.terminal_id then
        return false
      end
      return true
    end

    -- Is this record still the surface we created? Refreshes the record's cached
    -- label, and for a tab re-points pane_id at a live pane in that tab (the
    -- root pane can be closed while the tab lives on) — only ever adopting a
    -- pane that carries our own tag.
    function M.check(rec, panes)
      if rec.kind == "tab" then
        local candidate = rec.pane_id and panes[rec.pane_id]
        if not (candidate and candidate.tab_id == rec.tab_id and still_ours(candidate, rec)) then
          candidate = nil
          for _, p in pairs(panes) do
            if p.tab_id == rec.tab_id and M.is_tagged(p.label) then
              candidate = p
              break
            end
          end
        end
        if not candidate then
          return false
        end
        rec.pane_id, rec.terminal_id, rec.label = candidate.pane_id, candidate.terminal_id, candidate.label
        return true
      end

      local p = rec.pane_id and panes[rec.pane_id]
      if not still_ours(p, rec) then
        return false
      end
      rec.label = p.label
      return true
    end

    -- Check the whole registry against live state, dropping what is gone.
    -- Returns (live_names, dead_names, err), both sorted.
    function M.verify(opts)
      opts = opts or {}
      local panes, err = M.live_panes()
      if not panes then
        return nil, nil, err
      end

      local live, dead = {}, {}
      for name, rec in pairs(M.surfaces) do
        table.insert(M.check(rec, panes) and live or dead, name)
      end
      if opts.prune ~= false then
        for _, name in ipairs(dead) do
          M.surfaces[name] = nil
        end
      end
      table.sort(live)
      table.sort(dead)
      return live, dead, nil
    end

    -- Accepts a name or a label, like every other target in this plugin.
    function M.get(target)
      return M.find(target)
    end

    function M.forget(target)
      local rec = M.find(target)
      if rec then
        M.surfaces[rec.name] = nil
      end
      return rec
    end

    -- Resolve a target to (pane_id, record). A target is either a registered
    -- surface name, a raw pane id, or a raw tab id — a tab id resolves through
    -- pane.list to that tab's focused pane, since input needs a pane.
    -- opts.verify = false skips the liveness check. Only the creation path uses
    -- that, since a brand-new surface is not tagged yet at that point.
    function M.resolve_pane(target, opts)
      opts = opts or {}
      if type(target) ~= "string" or target == "" then
        return nil, nil, "no target given"
      end

      local rec = M.find(target)
      if rec then
        if opts.verify == false then
          return rec.pane_id, rec, nil
        end
        local panes, err = M.live_panes()
        if not panes then
          return nil, nil, err
        end
        if not M.check(rec, panes) then
          -- Key by rec.name, not target: target may have been a label.
          M.surfaces[rec.name] = nil
          return nil, nil, string.format("surface %q is gone — dropped from the registry", rec.name)
        end
        return rec.pane_id, rec, nil
      end

      if target:match("^[^:]+:p") then
        return target, nil, nil
      end

      if target:match("^[^:]+:t") then
        local result, err = M.call("pane.list")
        if not result then
          return nil, nil, err
        end
        local first
        for _, p in ipairs(result.panes or {}) do
          if p.tab_id == target then
            first = first or p.pane_id
            if p.focused then
              return p.pane_id, nil, nil
            end
          end
        end
        if first then
          return first, nil, nil
        end
        return nil, nil, "no pane found in tab " .. target
      end

      return nil, nil, "unknown surface name or id: " .. target
    end

    -- Open a plugin pane and register it.
    --
    -- The schema marks plugin.pane.open's reply as carrying `plugin_pane` with
    -- the new pane in it, but a popup does not come back that way — herdr's app
    -- runtime creates popups asynchronously and answers without the pane. So:
    -- use the payload when it is there, and otherwise diff pane.list around the
    -- call and take the pane that appeared. The raw reply is kept in
    -- M.last_response either way, because this is the one shape we could not
    -- pin down from the schema alone.
    function M.open_plugin_pane(params, opts)
      opts = opts or {}

      local before = M.live_panes() or {}

      local result, err = M.call("plugin.pane.open", params)
      M.last_response = result or err
      if not result then
        return nil, err
      end

      -- A popup is not addressable, and no amount of polling makes it so.
      -- Measured against protocol 19: plugin.pane.open answers {"type":"ok"}
      -- with no plugin_pane payload, and the pane it created appears in
      -- neither pane.list nor session.snapshot. There is therefore no pane_id
      -- to send text to, rename, or register — a popup is configured entirely
      -- by the env handed over at open time, and ends when its process exits
      -- or popup.close is called.
      --
      -- It also has to be focused. Opened with focus = false the popup is not
      -- even the "current" popup (popup.close answers popup_not_open) and its
      -- process does not survive; callers below always ask for focus.
      if params.placement == "popup" then
        return {
          kind = "popup",
          name = opts.name,
          label = opts.label,
          entrypoint = params.entrypoint,
          transient = true, -- no pane_id: cannot be addressed after this call
        }, nil
      end

      local function ids_from(pane, entrypoint)
        return {
          pane_id = pane.pane_id,
          terminal_id = pane.terminal_id,
          tab_id = pane.tab_id,
          workspace_id = pane.workspace_id,
          label = pane.label,
          entrypoint = entrypoint,
        }
      end

      local ids
      local payload = result.plugin_pane
      if payload and payload.pane then
        ids = ids_from(payload.pane, payload.entrypoint)
      else
        -- A popup takes a moment to exist; poll briefly for the new pane. The
        -- diff is by terminal_id, not pane id: a popup may land in a slot whose
        -- pane id was used before, and that would not look new.
        local seen = {}
        for _, p in pairs(before) do
          if p.terminal_id then
            seen[p.terminal_id] = true
          end
        end
        for _ = 1, 25 do
          local after = M.live_panes() or {}
          for _, p in pairs(after) do
            if p.terminal_id and not seen[p.terminal_id] then
              ids = ids_from(p, params.entrypoint)
              break
            end
          end
          if ids then
            break
          end
          vim.wait(60)
        end
      end

      if not ids then
        return nil, "plugin.pane.open returned without a pane, and no new pane "
          .. "appeared in pane.list (inspect _G.f_herdr.last_response)"
      end

      local rec = M.record("popup", ids, opts)
      M.apply_tag(rec, opts.label)
      return rec, nil
    end

    -- A popup running an interactive shell, optionally running opts.cmd first.
    --
    -- Everything the popup needs is decided here, at open time, because a popup
    -- cannot be talked to afterwards (see open_plugin_pane). Both the working
    -- directory and the command travel in the `env` map:
    --
    --   * cwd, because herdr resolves the manifest's relative command
    --     ("sh shell.sh") against the pane's cwd — setting plugin.pane.open's
    --     `cwd` to the caller's directory makes the script unfindable, and the
    --     popup dies with exit 2 before it is ever drawn.
    --   * cmd, because pane.send_text needs a pane_id and a popup has none.
    --
    -- Neither is interpolated into a shell word: shell.sh cds to one and hands
    -- the other to the shell as its -c argument.
    function M.popup_shell(opts)
      opts = opts or {}

      -- Same placement rules as popup_pane: no workspace_id / target_pane_id.
      -- focus is not optional — an unfocused popup does not survive.
      local params = {
        plugin_id = M.plugin_id,
        entrypoint = M.plugin_shell_entrypoint,
        placement = "popup",
        focus = true,
        env = {},
      }
      if opts.cwd then
        params.env.F_HERDR_SHELL_CWD = opts.cwd
      end
      if opts.cmd then
        params.env.F_HERDR_SHELL_CMD = opts.cmd
      end
      if opts.width then
        params.width = opts.width
      end
      if opts.height then
        params.height = opts.height
      end

      return M.open_plugin_pane(params, opts)
    end

    -- (d) A new tab in the same workspace, whose root pane is a shell.
    -- focus defaults to false — herdr's own default, so the tab spins up behind
    -- whatever you are doing. Pass focus = true to be switched to it.
    function M.new_tab(opts)
      opts = opts or {}

      -- Tag the label at creation, so the tab is verifiable from the moment it
      -- exists rather than after a follow-up rename.
      local params = { focus = opts.focus == true, label = M.tagged(opts.label) }
      if opts.cwd then
        params.cwd = opts.cwd
      end
      if opts.env then
        params.env = opts.env
      end
      -- tab.create takes workspace_id (unlike popup panes), so stay in our own
      -- workspace rather than whichever one happens to be focused.
      params.workspace_id = opts.workspace_id
      if not params.workspace_id then
        local pane = M.this_pane()
        if pane then
          params.workspace_id = pane.workspace_id
        end
      end

      local result, err = M.call("tab.create", params)
      if not result then
        return nil, err
      end

      local rec = M.record("tab", {
        tab_id = result.tab.tab_id,
        pane_id = result.root_pane.pane_id,
        terminal_id = result.root_pane.terminal_id,
        workspace_id = result.tab.workspace_id,
        label = result.tab.label,
      }, opts)
      -- The tab label carries the tag already; the root pane needs it too, so a
      -- single pane.list can answer liveness for tabs and popups alike.
      M.apply_tag(rec, opts.label or rec.name)

      if opts.cmd then
        local _, run_err = M.run(rec.name, opts.cmd)
        if run_err then
          return rec, run_err
        end
      end
      return rec, nil
    end

    -- Set the label herdr shows for a surface: tab.rename for a tab, pane.rename
    -- for a pane or popup. Keeps the record's cached label in sync.
    --
    -- Renaming one of ours keeps the tag, otherwise the rename would make our
    -- own surface look dead. A raw id that we did not create is renamed verbatim
    -- — no reason to stamp a stranger's pane.
    function M.rename(target, label)
      local rec = M.find(target)
      if rec then
        -- One path for ours: apply_tag relabels the tab and its root pane, and
        -- keeps the marker so the surface stays verifiable.
        local _, err = M.apply_tag(rec, label)
        if err then
          return nil, err
        end
        return rec, nil
      end

      if target:match("^[^:]+:t") then
        local result, err = M.call("tab.rename", { tab_id = target, label = label })
        if not result then
          return nil, err
        end
        return { kind = "tab", tab_id = target, label = label }
      end

      local pane_id, _, resolve_err = M.resolve_pane(target, { verify = false })
      if not pane_id then
        return nil, resolve_err
      end
      local result, err = M.call("pane.rename", { pane_id = pane_id, label = label })
      if not result then
        return nil, err
      end
      return { kind = "popup", pane_id = pane_id, label = label }
    end

    ---------------------------------------------------------------------------
    -- input
    ---------------------------------------------------------------------------

    -- Literal text, as a paste. Note this is NOT how you run a command: see M.run.
    function M.send_text(target, text)
      local pane_id, _, err = M.resolve_pane(target)
      if not pane_id then
        return nil, err
      end
      return M.call("pane.send_text", { pane_id = pane_id, text = text })
    end

    -- Real key presses. keys is a herdr key name or a list of them — "Enter",
    -- "Tab", "esc" (canonical; "escape" also accepted), "ctrl+c", "PageUp", "F5".
    function M.send_keys(target, keys)
      local pane_id, _, err = M.resolve_pane(target)
      if not pane_id then
        return nil, err
      end
      if type(keys) == "string" then
        keys = { keys }
      end
      return M.call("pane.send_keys", { pane_id = pane_id, keys = keys })
    end

    -- Text and keys in one request, herdr's combined verb.
    function M.send_input(target, text, keys)
      local pane_id, _, err = M.resolve_pane(target)
      if not pane_id then
        return nil, err
      end
      local params = { pane_id = pane_id }
      if text then
        params.text = text
      end
      if keys then
        params.keys = type(keys) == "string" and { keys } or keys
      end
      return M.call("pane.send_input", params)
    end

    -- Read a pane back. source is "visible", "recent", "recent_unwrapped" or
    -- "detection". Returns the text, which is how you confirm a command ran.
    function M.read(target, source, lines)
      local pane_id, _, err = M.resolve_pane(target)
      if not pane_id then
        return nil, err
      end
      local result, read_err = M.call("pane.read", {
        pane_id = pane_id,
        source = source or "visible",
        lines = lines or 40,
      })
      if not result then
        return nil, read_err
      end
      return result.read.text, nil
    end

    -- Poll the pane's visible text until predicate passes. Best effort: returns
    -- false on timeout and callers proceed anyway, so a slow or unusual shell
    -- degrades to blind sending rather than hanging.
    --
    -- vim.wait() with no condition is the delay on purpose — a real sleep would
    -- stall the event loop, and M.call needs that loop running to receive its
    -- reply, so sleeping here would deadlock the next read.
    local function wait_for(pane_id, predicate, attempts)
      for _ = 1, attempts or 40 do
        local result = M.call("pane.read", { pane_id = pane_id, source = "visible", lines = 20 })
        local text = result and result.read and result.read.text
        if text and predicate(text) then
          return true
        end
        vim.wait(80)
      end
      return false
    end

    -- Run a shell command in a surface, pacing to the shell's startup.
    --
    -- Submission is a real Enter key, never a trailing "\n" in the text: herdr
    -- delivers text as a paste, and once a line editor (zsh ZLE) is live an
    -- embedded newline is inserted literally instead of executing the line — so
    -- the command would just sit at the prompt. Two startup races to dodge:
    -- typing before a shell exists (keystrokes are dropped), and pressing Enter
    -- before the line editor has the text (the line is lost).
    function M.run(target, cmd)
      local pane_id, _, err = M.resolve_pane(target)
      if not pane_id then
        return nil, err
      end

      -- 1. wait for a prompt — any non-blank content means the shell is up.
      wait_for(pane_id, function(t)
        return t:match("%S") ~= nil
      end)

      -- 2. type it, with no trailing newline.
      local ok, send_err = M.call("pane.send_text", { pane_id = pane_id, text = cmd })
      if not ok then
        return nil, send_err
      end

      -- 3. wait for the echo, proving the line editor accepted it. The probe is
      -- a short leading fragment: a long command wraps across rows, so matching
      -- the whole string against the rendered screen would fail.
      local probe = vim.trim((cmd:match("^[^\n]*") or ""):sub(1, 12))
      if probe ~= "" then
        wait_for(pane_id, function(t)
          return t:find(probe, 1, true) ~= nil
        end)
      end

      -- 4. submit.
      return M.call("pane.send_keys", { pane_id = pane_id, keys = { "Enter" } })
    end

    ---------------------------------------------------------------------------
    -- commands
    ---------------------------------------------------------------------------

    local function echo(lines, hl)
      local chunks = {}
      for _, l in ipairs(lines) do
        table.insert(chunks, { l .. "\n", hl })
      end
      vim.api.nvim_echo(chunks, true, {})
    end

    vim.api.nvim_create_user_command("HerdrEnding", function()
      local f = M.file_ending(0)
      echo({
        string.format("path      %s", f.path or "<no name>"),
        string.format("ending    %s", f.ending or "<none>"),
        string.format("filetype  %s", f.filetype or "<none>"),
      })
    end, { desc = "herdr (a): show this buffer's file ending and filetype" })

    -- :HerdrCheck — the first thing to run on a new machine. Walks what can be
    -- wrong, in order, and stops at the first one that is. A live pane.list is
    -- the real proof of the socket: it needs the server listening, parsing and
    -- answering. The plugin line is the other half — popups cannot open until
    -- the manifest is linked, and that is a separate, explicit step.
    vim.api.nvim_create_user_command("HerdrCheck", function()
      local lines = { { "=== herdr check ===\n", "Title" } }
      local function add(label, value, hl)
        table.insert(lines, { string.format("%-10s %s\n", label, value), hl })
      end

      local path, err = M.socket_path()
      add("env", vim.env.HERDR_SOCKET_PATH or "<unset>", path and "None" or "ErrorMsg")
      if not path then
        add("status", "DOWN — " .. err, "ErrorMsg")
        vim.api.nvim_echo(lines, true, {})
        return
      end
      add("pane", vim.env.HERDR_PANE_ID or "<unset>")

      -- pane.list takes no params, so it works even without HERDR_PANE_ID.
      local result, call_err = M.call("pane.list")
      if not result then
        add("status", "DOWN — " .. call_err, "ErrorMsg")
        vim.api.nvim_echo(lines, true, {})
        return
      end
      add("status", "UP — socket answered pane.list", "DiagnosticOk")
      add("panes", tostring(#(result.panes or {})))

      local info, info_err = M.plugin_info()
      if info then
        local ids = {}
        for _, p in ipairs(info.panes or {}) do
          table.insert(ids, p.id)
        end
        add("plugin", string.format("%s v%s enabled=%s [%s]", info.plugin_id,
          tostring(info.version), tostring(info.enabled), table.concat(ids, " ")), "DiagnosticOk")
      elseif info_err then
        add("plugin", "unknown — " .. info_err, "ErrorMsg")
      else
        add("plugin", M.plugin_id .. " NOT linked — run :HerdrPluginLink", "WarningMsg")
      end

      vim.api.nvim_echo(lines, true, {})
    end, { desc = "herdr: check the socket is reachable and the plugin is linked" })

    vim.api.nvim_create_user_command("HerdrWhere", function()
      -- Parenthesised: context_lines returns (lines, ctx) and echo's second
      -- argument is a highlight group.
      echo((M.context_lines()))
    end, { desc = "herdr (b): show the pane/tab/workspace nvim is running in" })

    vim.api.nvim_create_user_command("HerdrPopup", function()
      M.popup(M.context_lines(), { title = " herdr context (q to close) " })
    end, { desc = "herdr (c): show the herdr context in a floating popup" })

    vim.api.nvim_create_user_command("HerdrPopupPane", function()
      local result, err = M.popup_pane(M.context_lines(), { width = "70%", height = "50%" })
      if not result then
        echo({ "herdr: " .. err }, "ErrorMsg")
        return
      end
      echo(vim.split(vim.inspect(result), "\n"))
    end, { desc = "herdr (c): show the herdr context in a real herdr popup pane" })

    vim.api.nvim_create_user_command("HerdrPopupClose", function()
      local result, err = M.call("popup.close")
      if not result then
        echo({ "herdr: " .. err }, "ErrorMsg")
        return
      end
      echo({ "popup closed" })
    end, { desc = "herdr (c): close the current herdr popup" })

    -- Report a created surface the same way every time, so the name to reuse is
    -- always the first thing on screen.
    local function echo_surface(rec, err)
      if not rec then
        echo({ "herdr: " .. tostring(err) }, "ErrorMsg")
        return
      end
      -- A popup has no ids to report and is not in the registry, so say that
      -- rather than printing a row of dashes that looks like a failure.
      if rec.transient then
        echo({
          string.format("kind        %s (%s)", rec.kind, rec.entrypoint or "-"),
          "opened      yes — herdr popups have no pane id, so this one is not",
          "            registered and cannot be sent to afterwards",
        })
      else
        echo({
          string.format("name        %s", rec.name or "-"),
          string.format("kind        %s", rec.kind),
          string.format("pane        %s", rec.pane_id or "-"),
          string.format("terminal    %s", rec.terminal_id or "-"),
          string.format("tab         %s", rec.tab_id or "-"),
          string.format("workspace   %s", rec.workspace_id or "-"),
          string.format("label       %s", rec.label or "-"),
        })
      end
      if err then
        echo({ "warning: " .. tostring(err) }, "WarningMsg")
      end
    end

    -- :HerdrPopupShell [cmd]   popup running a shell, optionally running cmd
    -- first. Always focused: an unfocused popup does not survive.
    vim.api.nvim_create_user_command("HerdrPopupShell", function(opts)
      echo_surface(M.popup_shell({
        cmd = opts.args ~= "" and opts.args or nil,
        cwd = vim.fn.getcwd(),
      }))
    end, { nargs = "*", desc = "herdr: popup running a shell, optionally running a command" })

    -- :HerdrTab [label]   new tab in this workspace; bang focuses it.
    -- The label doubles as the registry name, so :HerdrTab build gives you a
    -- surface you can address as "build" rather than as "tab2".
    vim.api.nvim_create_user_command("HerdrTab", function(opts)
      local label = opts.args ~= "" and opts.args or nil
      echo_surface(M.new_tab({
        label = label,
        name = label,
        focus = opts.bang,
        cwd = vim.fn.getcwd(),
      }))
    end, { nargs = "*", bang = true, desc = "herdr (d): new tab here; :HerdrTab! focuses it" })

    -- Lists only what is still live: every entry is checked against pane.list and
    -- its tag, and anything the user closed in the meantime is dropped. Bang
    -- keeps the dead entries instead of pruning, for when you want to see them.
    vim.api.nvim_create_user_command("HerdrSurfaces", function(opts)
      local live, dead, err = M.verify({ prune = not opts.bang })
      if err then
        echo({ "herdr: " .. err }, "ErrorMsg")
        return
      end

      if #live == 0 and #dead == 0 then
        echo({ "no surfaces created yet" }, "WarningMsg")
        return
      end

      local lines = {
        string.format("owner %s   tag %s", M.owner_id() or "<unknown>", M.tag()),
        string.format("%-12s %-6s %-8s %-8s %-18s %s", "NAME", "KIND", "PANE", "TAB", "TERMINAL", "LABEL"),
      }
      for _, name in ipairs(live) do
        local s = M.surfaces[name]
        table.insert(lines, string.format("%-12s %-6s %-8s %-8s %-18s %s",
          name, s.kind, s.pane_id or "-", s.tab_id or "-", s.terminal_id or "-", s.label or "-"))
      end
      echo(lines)

      if #dead > 0 then
        echo({ string.format("%s %s: %s",
          #dead, opts.bang and "dead (kept)" or "gone (dropped)", table.concat(dead, " ")) }, "WarningMsg")
      end
    end, { bang = true, desc = "herdr: list the live popups and tabs f-herdr created, by name" })

    -- Shared completion: registered names first, they are what you usually want.
    local function complete_target(arg)
      local names = vim.tbl_keys(M.surfaces)
      table.sort(names)
      return vim.tbl_filter(function(n)
        return n:find(arg, 1, true) == 1
      end, names)
    end

    -- :HerdrRun <target> <cmd...>
    vim.api.nvim_create_user_command("HerdrRun", function(opts)
      local target, cmd = opts.args:match("^(%S+)%s+(.+)$")
      if not target then
        echo({ "usage: :HerdrRun <name|pane-id|tab-id> <command...>" }, "WarningMsg")
        return
      end
      local ok, err = M.run(target, cmd)
      echo({ ok and ("ran in " .. target .. ": " .. cmd) or ("herdr: " .. tostring(err)) },
        ok and nil or "ErrorMsg")
    end, { nargs = "+", complete = complete_target, desc = "herdr (e): run a command in a surface" })

    -- :HerdrType <target> <text...>   literal paste, no Enter
    vim.api.nvim_create_user_command("HerdrType", function(opts)
      local target, text = opts.args:match("^(%S+)%s+(.+)$")
      if not target then
        echo({ "usage: :HerdrType <name|pane-id> <text...>" }, "WarningMsg")
        return
      end
      local ok, err = M.send_text(target, text)
      echo({ ok and ("typed into " .. target) or ("herdr: " .. tostring(err)) }, ok and nil or "ErrorMsg")
    end, { nargs = "+", complete = complete_target, desc = "herdr (e): send literal text to a surface" })

    -- :HerdrSend <target> <key> [key...]   real key presses
    vim.api.nvim_create_user_command("HerdrSend", function(opts)
      local target = opts.fargs[1]
      local keys = vim.list_slice(opts.fargs, 2)
      if not target or #keys == 0 then
        echo({ "usage: :HerdrSend <name|pane-id> <key> [key...]   e.g. :HerdrSend tab1 ctrl+c Enter" },
          "WarningMsg")
        return
      end
      local ok, err = M.send_keys(target, keys)
      echo({ ok and ("sent " .. table.concat(keys, " ") .. " to " .. target) or ("herdr: " .. tostring(err)) },
        ok and nil or "ErrorMsg")
    end, { nargs = "+", complete = complete_target, desc = "herdr (e): send key presses to a surface" })

    -- :HerdrRead <target>
    vim.api.nvim_create_user_command("HerdrRead", function(opts)
      local text, err = M.read(opts.fargs[1], "visible", 40)
      if not text then
        echo({ "herdr: " .. tostring(err) }, "ErrorMsg")
        return
      end
      echo(vim.split(text, "\n"))
    end, { nargs = 1, complete = complete_target, desc = "herdr: read a surface's visible output back" })

    -- :HerdrRename <target> <label...>
    vim.api.nvim_create_user_command("HerdrRename", function(opts)
      local target, label = opts.args:match("^(%S+)%s+(.+)$")
      if not target then
        echo({ "usage: :HerdrRename <name|pane-id|tab-id> <label...>" }, "WarningMsg")
        return
      end
      local rec, err = M.rename(target, label)
      echo({ rec and ("renamed " .. target .. " to " .. label) or ("herdr: " .. tostring(err)) },
        rec and nil or "ErrorMsg")
    end, { nargs = "+", complete = complete_target, desc = "herdr: set a surface's herdr label" })

    vim.api.nvim_create_user_command("HerdrPluginLink", function()
      local result, err = M.plugin_link()
      if not result then
        echo({ "herdr: " .. err }, "ErrorMsg")
        return
      end
      echo(vim.split(vim.inspect(result), "\n"))
    end, { desc = "herdr: register f-herdr's manifest with the running herdr" })

    vim.api.nvim_create_user_command("HerdrPluginList", function()
      local info, err = M.plugin_info()
      if err then
        echo({ "herdr: " .. err }, "ErrorMsg")
        return
      end
      if not info then
        echo({
          M.plugin_id .. " is NOT linked",
          "manifest: " .. M.plugin_dir .. "/herdr-plugin.toml",
          "run :HerdrPluginLink",
        }, "WarningMsg")
        return
      end

      -- herdr caches the manifest in plugins.json, so the entrypoints it knows
      -- about can lag the file on disk. Lead with them: a missing "shell" here
      -- is why plugin.pane.open would fail, and :HerdrPluginLink is the fix.
      local lines = { string.format("%s  v%s  enabled=%s",
        info.plugin_id, tostring(info.version), tostring(info.enabled)) }
      local ids = {}
      for _, p in ipairs(info.panes or {}) do
        table.insert(ids, string.format("%s (%s)", p.id, p.placement or "?"))
      end
      table.insert(lines, "panes: " .. (#ids > 0 and table.concat(ids, ", ") or "<none>"))
      table.insert(lines, "root:  " .. tostring(info.plugin_root))
      echo(lines)
    end, { desc = "herdr: show whether f-herdr is registered as a herdr plugin" })

    vim.api.nvim_create_user_command("HerdrCall", function(opts)
      local method, rest = opts.args:match("^(%S+)%s*(.*)$")
      if not method then
        echo({ "usage: :HerdrCall <method> [json-params]" }, "WarningMsg")
        return
      end

      local params
      if rest ~= "" then
        local ok, decoded = pcall(vim.json.decode, rest)
        if not ok then
          echo({ "bad json params: " .. rest }, "ErrorMsg")
          return
        end
        params = decoded
      end

      local result, err = M.call(method, params)
      if not result then
        echo({ "herdr: " .. err }, "ErrorMsg")
        return
      end
      echo(vim.split(vim.inspect(result), "\n"))
    end, { nargs = "+", desc = "herdr: call a raw socket method" })

    vim.g.f_herdr = "loaded (config ran)"
    _G.f_herdr = M
  end,
}
