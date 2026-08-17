-- f_target: one answer to "where does output go".
--
-- The companion to f_venv. f_venv answers "which python does this buffer
-- belong to" so the REPL and the tools that talk to it cannot disagree; this
-- answers the other half — which surface, in which workspace, in which herdr
-- session — so iron.lua and f_visi_h_pane.lua cannot disagree either.
--
-- Three independent destinations, each set from the Åä menu:
--
--   M.repl   where Åss / Åsf / Ås / Åsb / Åt / År / Åf / Åö send
--              iron    in-nvim split (iron.nvim)                 [default]
--              local   an auto-named tab in this workspace, per filetype
--                      (ipyOut / rustRepl / bashOut / termOut)
--              pane    one specific pane, any workspace, any session
--
--   M.visi   where Åv / :FVisiHPane create the self-destructing visidata tab
--              local       this workspace                        [default]
--              workspace   a chosen workspace, any session
--
--   M.bash   what Åpp / Åpf do with a .sh line
--              local_pane   reusable split in this workspace      [default]
--              popup        one-shot herdr popup (needs :HerdrPluginLink)
--              remote_pane  reusable split in a chosen workspace, any session
--
-- Two deliberate asymmetries:
--
--   * M.repl names a *pane*, because input needs a pane. M.visi and the pane
--     modes of M.bash name a *workspace*, because they create their own surface
--     inside it and only need to know where.
--
--   * M.repl is filetype-blind on purpose. Pin a pane and both python and bash
--     sends go there, whatever the buffer is. That is why iron.lua asks
--     f_herdr.process_summary what is actually running in a pinned pane rather
--     than assuming from the buffer's filetype — a wrong guess there does not
--     just pick the wrong REPL, it corrupts the paste (an ipython block needs a
--     blank line to close, a bash line does not).
--
-- State is per nvim instance. This is a module, so its state lives in this
-- nvim's Lua state and nowhere else: a second nvim in another workspace holds
-- its own targets and its own REPL, and neither can see the other's. That is
-- the same isolation f-herdr's owner tag gives to created surfaces.
--
-- Nothing here is persisted. A target points at a live terminal_id, and those
-- do not survive a herdr restart, so remembering one across nvim restarts would
-- only mean restoring a pointer that is already stale.

local M = {}

---------------------------------------------------------------------------
-- state
---------------------------------------------------------------------------

M.repl = { kind = "iron" }
M.visi = { kind = "local" }
M.bash = { kind = "local_pane" }

-- f-herdr's socket client, looked up at call time rather than at require time:
-- f-herdr is a lazy = false plugin spec and its config may not have run when
-- this module is first required. Returns (client, nil) or (nil, reason).
function M.herdr()
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

---------------------------------------------------------------------------
-- describing a target
---------------------------------------------------------------------------

local function tilde(path)
  if type(path) ~= "string" or path == "" then
    return "-"
  end
  local home = vim.env.HOME
  if home and path:sub(1, #home) == home then
    return "~" .. path:sub(#home + 1)
  end
  return path
end

-- "default/w2:p1" for a foreign session, "w2:p1" for this one.
local function qualify(t, where)
  if t and t.session and not t.is_this then
    return t.session .. "/" .. where
  end
  return where
end

-- The three glyphs mean one thing each, so a glance at :HerdrTargets answers
-- "how far away is this":
--
--   💻  inside nvim
--   🏠  this herdr session
--   📡  another herdr session
--
-- Picking a workspace of your own session through the "remote pane" route is
-- perfectly legal — it just means "a pane over there" — so the glyph follows
-- is_this rather than the kind, or that case would claim to be remote.
local function glyph(t)
  return (t and t.session and not t.is_this) and "📡" or "🏠"
end

function M.describe_repl()
  local t = M.repl
  if t.kind == "iron" then
    return "💻 iron (in-nvim split)"
  elseif t.kind == "local" then
    return "🏠 local workspace — auto tab per filetype"
  end
  return glyph(t) .. " " .. qualify(t, t.pane_id) .. (t.label and (" " .. t.label) or "")
end

function M.describe_visi()
  local t = M.visi
  if t.kind == "local" then
    return "🏠 local workspace"
  end
  local where = qualify(t, t.workspace_id)
  local label = (t.ws_label and t.ws_label ~= "") and (" " .. t.ws_label) or ""
  return glyph(t) .. " " .. where .. label
end

function M.describe_bash()
  local t = M.bash
  if t.kind == "popup" then
    return "🏠 local popup (one-shot)"
  elseif t.kind == "local_pane" then
    return "🏠 local pane (reusable)"
  end
  local label = (t.ws_label and t.ws_label ~= "") and (" " .. t.ws_label) or ""
  return glyph(t) .. " " .. qualify(t, t.workspace_id) .. label .. " pane (reusable)"
end

---------------------------------------------------------------------------
-- row formatting
---------------------------------------------------------------------------

-- workspace.number is what herdr shows on the workspace bar and workspace_id is
-- what the API takes, and they diverge — a workspace whose id is w4 can be
-- displayed as #3, because ids are not renumbered when a workspace closes. Rows
-- therefore show the number the user recognises and carry the id we send.
local function ws_text(row)
  local n = row.ws_number and ("#" .. tostring(row.ws_number)) or row.workspace_id
  local label = row.ws_label
  if label and label ~= "" then
    return string.format("%s %s", n, label)
  end
  return n
end

local function label_text(row)
  local label = row.label
  if label and label ~= "" then
    return "'" .. label .. "'"
  end
  return "-"
end

-- Column widths are measured across the whole row set rather than guessed,
-- because how wide these get depends entirely on the machine: a session named
-- "default" against one named "j", a workspace labelled with a path against one
-- with no label at all. Every row carries a reference to the same widths table,
-- since vim.ui.select's format_item sees one item at a time and has no other way
-- to know what its neighbours look like.
--
-- The session column collapses to nothing when every row is in this session,
-- which is the common case and the one worth keeping narrow.
local function measure(rows)
  local w = { session = 0, ws = 0, pane = 0, label = 0 }
  for _, row in ipairs(rows) do
    if not row.is_this then
      w.session = math.max(w.session, vim.fn.strdisplaywidth(row.session or ""))
    end
    w.ws = math.max(w.ws, vim.fn.strdisplaywidth(ws_text(row)))
    w.pane = math.max(w.pane, vim.fn.strdisplaywidth(row.pane_id or ""))
    w.label = math.max(w.label, vim.fn.strdisplaywidth(label_text(row)))
  end
  for _, row in ipairs(rows) do
    row.w = w
  end
  return w
end

-- Pad to a display width. Not string.format("%-Ns"), which counts bytes: a
-- workspace labelled "clöd" or an agent pane titled with a glyph would throw
-- every following column out.
local function pad(s, width)
  s = tostring(s or "")
  return s .. string.rep(" ", math.max(0, (width or 0) - vim.fn.strdisplaywidth(s)))
end

local function session_cell(row)
  local width = row.w and row.w.session or 0
  if width == 0 then
    return ""
  end
  return pad(row.is_this and "" or row.session, width) .. "  "
end

local function pane_row_text(row)
  local w = row.w or {}
  local bits = {
    session_cell(row) .. pad(ws_text(row), w.ws),
    pad(row.pane_id, w.pane),
    pad(label_text(row), w.label),
  }
  if row.agent then
    table.insert(bits, "[" .. row.agent .. "]")
  end
  table.insert(bits, tilde(row.cwd))
  return "📡 " .. table.concat(bits, "  ")
end

local function ws_row_text(row)
  local w = row.w or {}
  return string.format("📡 %s%s  tabs=%s panes=%s",
    session_cell(row), pad(ws_text(row), w.ws),
    tostring(row.tab_count or "?"), tostring(row.pane_count or "?"))
end

-- Show whatever went wrong while building rows, without stopping the picker.
local function warn_errors(errors)
  for _, e in ipairs(errors or {}) do
    if e then
      vim.notify("f_target: " .. tostring(e), vim.log.levels.WARN)
    end
  end
end

---------------------------------------------------------------------------
-- enumeration for the pickers
---------------------------------------------------------------------------

-- Every pane of every running session, already annotated with the workspace it
-- lives in and the session it belongs to.
--
-- Cost is two socket round-trips per session — pane.list plus workspace.list —
-- and NOT one per pane. pane.process_info would say what is actually running in
-- each pane, which would make prettier rows, but it is one blocking round-trip
-- each: over three sessions with a dozen panes that is a visible stall every
-- time you press Åä. So it is fetched once, for the pane you actually choose.
--
-- Returns (rows, errors). Errors are per session and non-fatal: a session that
-- has gone away since `herdr session list` should not blank the picker.
function M.enumerate_panes(fh)
  local sessions, err = fh.sessions()
  if not sessions then
    return nil, { err }
  end

  local rows, errors = {}, {}
  local my_pane = vim.env.HERDR_PANE_ID

  for _, s in ipairs(sessions) do
    if s.degraded then
      table.insert(errors, s.degraded)
    end

    local workspaces, ws_err = fh.workspaces_on(s.socket)
    local panes, pane_err = fh.panes_on(s.socket)
    if not panes then
      table.insert(errors, string.format("%s: %s", s.name, tostring(pane_err)))
    else
      local ws_by_id = {}
      for _, w in ipairs(workspaces or {}) do
        ws_by_id[w.workspace_id] = w
      end
      if not workspaces then
        table.insert(errors, string.format("%s: %s", s.name, tostring(ws_err)))
      end

      for _, p in ipairs(panes) do
        -- Never offer the pane nvim is running in: sending there types into
        -- this editor. Scoped by session as well as by id, because a pane id is
        -- only unique within its own session.
        local is_me = s.is_this and my_pane and p.pane_id == my_pane
        if not is_me then
          local w = ws_by_id[p.workspace_id]
          table.insert(rows, {
            kind = "pane",
            session = s.name,
            socket = s.socket,
            is_this = s.is_this,
            pane_id = p.pane_id,
            terminal_id = p.terminal_id,
            workspace_id = p.workspace_id,
            tab_id = p.tab_id,
            label = p.label,
            cwd = p.foreground_cwd or p.cwd,
            agent = p.agent,
            ws_number = w and w.number or nil,
            ws_label = w and w.label or nil,
          })
        end
      end
    end
  end

  measure(rows)
  return rows, errors
end

-- Every workspace of every running session.
function M.enumerate_workspaces(fh)
  local sessions, err = fh.sessions()
  if not sessions then
    return nil, { err }
  end

  local rows, errors = {}, {}
  for _, s in ipairs(sessions) do
    if s.degraded then
      table.insert(errors, s.degraded)
    end
    local workspaces, ws_err = fh.workspaces_on(s.socket)
    if not workspaces then
      table.insert(errors, string.format("%s: %s", s.name, tostring(ws_err)))
    else
      for _, w in ipairs(workspaces) do
        table.insert(rows, {
          kind = "workspace",
          session = s.name,
          socket = s.socket,
          is_this = s.is_this,
          workspace_id = w.workspace_id,
          ws_number = w.number,
          ws_label = w.label,
          tab_count = w.tab_count,
          pane_count = w.pane_count,
        })
      end
    end
  end
  measure(rows)
  return rows, errors
end

---------------------------------------------------------------------------
-- pickers
---------------------------------------------------------------------------
--
-- vim.ui.select, so there is no hard dependency on a picker plugin. It upgrades
-- for free the day fzf-lua's register_ui_select() is enabled, and works before
-- then. Every picker is callback-driven because vim.ui.select is.

-- The one extra round-trip we do pay, and only for the pane actually chosen:
-- what is running in it. Reported so a wrong pick is obvious immediately rather
-- than at the next send.
local function annotate_process(fh, row)
  local info = fh.process_summary(row)
  row.process = info and info.name or nil
  return row
end

function M.pick_repl(done)
  local fh, err = M.herdr()
  if not fh then
    vim.notify("herdr: " .. err, vim.log.levels.ERROR)
    return
  end

  local rows, errors = M.enumerate_panes(fh)
  warn_errors(errors)
  rows = rows or {}

  local items = {
    { kind = "iron" },
    { kind = "local" },
  }
  vim.list_extend(items, rows)

  vim.ui.select(items, {
    prompt = "REPL target — where Åss/Åsf/Ås/Åsb send:",
    format_item = function(item)
      if item.kind == "iron" then
        return "💻 iron — in-nvim split"
      elseif item.kind == "local" then
        return "🏠 local workspace — auto tab per filetype (ipyOut/bashOut/rustRepl)"
      end
      return pane_row_text(item)
    end,
  }, function(choice)
    if not choice then
      return
    end
    if choice.kind == "pane" then
      annotate_process(fh, choice)
    end
    M.repl = choice
    local extra = choice.process and ("  running " .. choice.process) or ""
    vim.notify("REPL target: " .. M.describe_repl() .. extra, vim.log.levels.INFO)
    if done then
      done(choice)
    end
  end)
end

function M.pick_visi(done)
  local fh, err = M.herdr()
  if not fh then
    vim.notify("herdr: " .. err, vim.log.levels.ERROR)
    return
  end

  local rows, errors = M.enumerate_workspaces(fh)
  warn_errors(errors)

  local items = { { kind = "local" } }
  vim.list_extend(items, rows or {})

  vim.ui.select(items, {
    prompt = "visidata target — where Åv creates its tab:",
    format_item = function(item)
      if item.kind == "local" then
        return "🏠 local workspace — this one"
      end
      return ws_row_text(item)
    end,
  }, function(choice)
    if not choice then
      return
    end
    M.visi = choice
    vim.notify("visidata target: " .. M.describe_visi(), vim.log.levels.INFO)
    if done then
      done(choice)
    end
  end)
end

function M.pick_bash(done)
  local fh, err = M.herdr()
  if not fh then
    vim.notify("herdr: " .. err, vim.log.levels.ERROR)
    return
  end

  -- No remote popup. plugin.pane.open refuses workspace_id / target_pane_id for
  -- placement = "popup" — a popup always opens over the focused pane of the
  -- session it is asked of — so a popup cannot be aimed at a workspace, only
  -- reached by focusing that workspace first and moving your view off nvim.
  -- Remote work goes to a real pane instead, which is addressable and reusable.
  local items = {
    { kind = "local_pane" },
    { kind = "popup" },
    { kind = "remote_pane_pick" },
  }

  vim.ui.select(items, {
    prompt = "Åpp bash target — where a .sh line runs:",
    format_item = function(item)
      if item.kind == "local_pane" then
        return "🏠 local pane — reusable split in this workspace"
      elseif item.kind == "popup" then
        return "🏠 local popup — one-shot, no shell state (needs :HerdrPluginLink)"
      end
      return "📡 remote pane — pick a workspace in any session…"
    end,
  }, function(choice)
    if not choice then
      return
    end

    if choice.kind ~= "remote_pane_pick" then
      M.bash = choice
      vim.notify("Åpp target: " .. M.describe_bash(), vim.log.levels.INFO)
      if done then
        done(choice)
      end
      return
    end

    -- Second stage: which workspace does the remote pane go in.
    local rows, errors = M.enumerate_workspaces(fh)
    warn_errors(errors)
    if not rows or #rows == 0 then
      vim.notify("f_target: no workspaces to choose from", vim.log.levels.WARN)
      return
    end

    vim.ui.select(rows, {
      prompt = "Åpp remote pane — which workspace:",
      format_item = ws_row_text,
    }, function(ws)
      if not ws then
        return
      end
      M.bash = {
        kind = "remote_pane",
        session = ws.session,
        socket = ws.socket,
        is_this = ws.is_this,
        workspace_id = ws.workspace_id,
        ws_number = ws.ws_number,
        ws_label = ws.ws_label,
      }
      vim.notify("Åpp target: " .. M.describe_bash(), vim.log.levels.INFO)
      if done then
        done(M.bash)
      end
    end)
  end)
end

-- The Åä menu: pick which destination to change, then change it.
function M.menu()
  local entries = {
    { key = "repl", label = "REPL      ", describe = M.describe_repl, pick = M.pick_repl },
    { key = "visi", label = "visidata  ", describe = M.describe_visi, pick = M.pick_visi },
    { key = "bash", label = "Åpp bash  ", describe = M.describe_bash, pick = M.pick_bash },
  }

  vim.ui.select(entries, {
    prompt = "f-herdr targets — which one to change:",
    format_item = function(e)
      return e.label .. e.describe()
    end,
  }, function(choice)
    if choice then
      choice.pick()
    end
  end)
end

---------------------------------------------------------------------------
-- reporting
---------------------------------------------------------------------------

-- The three targets and whether they are still there, for :HerdrTargets.
-- Cheaper to read than three separate failures at the keyboard.
function M.lines()
  local out = {}
  local function add(fmt, ...)
    table.insert(out, string.format(fmt, ...))
  end

  -- pad(), not "%-10s": the Å in "Åpp bash" is two bytes and one column, so a
  -- byte-counted width indents that row one short of the others.
  add("%s %s", pad("REPL", 10), M.describe_repl())
  add("%s %s", pad("visidata", 10), M.describe_visi())
  add("%s %s", pad("Åpp bash", 10), M.describe_bash())

  local fh, err = M.herdr()
  if not fh then
    add("")
    add("herdr     DOWN — %s", err)
    return out
  end

  -- Liveness only means anything for a pinned pane; the local/iron kinds cannot
  -- go stale because they are resolved fresh on every use.
  if M.repl.kind == "pane" then
    local pane, verr = fh.verify_target(M.repl)
    add("")
    if pane then
      local info = fh.process_summary(M.repl)
      add("REPL pane live — %s, running %s", pane.pane_id, (info and info.name) or "?")
    else
      add("REPL pane DEAD — %s", tostring(verr))
    end
  end

  local sessions, serr = fh.sessions()
  add("")
  if sessions then
    local names = {}
    for _, s in ipairs(sessions) do
      table.insert(names, s.name .. (s.is_this and " (this)" or ""))
    end
    add("sessions   %s", table.concat(names, ", "))
  else
    add("sessions   unknown — %s", tostring(serr))
  end

  return out
end

return M
