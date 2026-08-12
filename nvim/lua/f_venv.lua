-- f_venv: one answer to "which python environment does this buffer belong to".
--
-- Anchored on the *buffer*, not on nvim's cwd. cwd is where you happened to
-- start nvim; it is only the right answer while you stay inside one project.
-- Open a file from somewhere else without :cd and a cwd-anchored lookup finds
-- the wrong venv, or none.
--
-- Search order, first hit wins:
--
--   1. .venv / venv / env, walking up from the buffer's own directory. This is
--      the one that makes a buffer in src/deep/thing.py find the project root.
--   2. $VIRTUAL_ENV, when nvim itself was started inside an activated venv.
--   3. the same walk up from nvim's cwd — the fallback for a scratch buffer
--      that has no file on disk to walk up from.
--
-- A directory only counts as a venv if it actually has a bin/python, so an
-- unrelated directory called "env" is skipped rather than believed.
--
-- Used by iron.lua (which interpreter to start, which venv to activate in a
-- herdr tab) and f_visi_h_pane.lua (where vd is). One module so the REPL and
-- the tools that talk to it can never disagree about which project this is.

local M = {}

local NAMES = { ".venv", "venv", "env" }

-- Where the walk starts: the buffer's own directory, or cwd for a buffer with
-- no file behind it.
function M.anchor(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name == "" then
    return vim.fn.getcwd()
  end
  return vim.fn.fnamemodify(name, ":p:h")
end

local function is_venv(dir)
  return vim.fn.isdirectory(dir) == 1 and vim.fn.executable(dir .. "/bin/python") == 1
end

-- Walk up to the filesystem root. fnamemodify(:h) of "/" is "/", which is what
-- ends the loop.
local function upward(dir)
  while dir and dir ~= "" do
    for _, n in ipairs(NAMES) do
      local candidate = dir .. "/" .. n
      if is_venv(candidate) then
        return candidate
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      return nil
    end
    dir = parent
  end
  return nil
end

-- The venv for this buffer. Returns (path, how_it_was_found) or (nil, nil),
-- where the second value is for reporting: knowing a venv came from
-- $VIRTUAL_ENV rather than from the buffer is usually the answer to "why is it
-- using that python".
function M.venv(bufnr)
  local found = upward(M.anchor(bufnr))
  if found then
    return found, "buffer"
  end

  local env = os.getenv("VIRTUAL_ENV")
  if env and env ~= "" and is_venv(env) then
    return env, "$VIRTUAL_ENV"
  end

  found = upward(vim.fn.getcwd())
  if found then
    return found, "cwd"
  end

  return nil, nil
end

-- An executable from this buffer's venv, falling back to $PATH.
-- Returns (path, venv_or_nil) or (nil, nil).
function M.exe(name, bufnr)
  local venv = M.venv(bufnr)
  if venv and vim.fn.executable(venv .. "/bin/" .. name) == 1 then
    return venv .. "/bin/" .. name, venv
  end
  if vim.fn.executable(name) == 1 then
    return name, nil
  end
  return nil, nil
end

-- The interpreter to start, and whether it is an ipython — which decides more
-- than a banner: an ipython takes a pasted block and needs a blank line to
-- close it, a plain python does not.
--
-- Deliberately not M.exe("ipython"): the venv's own python beats an ipython
-- that only exists system-wide, because the venv is where the project's
-- packages are.
-- Returns (path, is_ipython, venv_or_nil).
function M.python(bufnr)
  local venv = M.venv(bufnr)
  if venv then
    if vim.fn.executable(venv .. "/bin/ipython") == 1 then
      return venv .. "/bin/ipython", true, venv
    end
    if vim.fn.executable(venv .. "/bin/python") == 1 then
      return venv .. "/bin/python", false, venv
    end
  end
  if vim.fn.executable("ipython") == 1 then
    return "ipython", true, nil
  end
  return "python3", false, nil
end

return M
