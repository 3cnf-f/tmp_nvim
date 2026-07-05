return {
  dir = vim.fn.stdpath("config"),
  name = "visi_tmux_pane",
  lazy = false,
  config = function()
    local function tmux_has_session(name)
      local ok = os.execute("tmux has-session -t=" .. name .. " 2>/dev/null")
      return ok == 0 or ok == true
    end

    local function tmux_window_exists(name)
      local handle = io.popen("tmux list-windows -a -F '#{window_name}' 2>/dev/null")
      if not handle then return false end
      local result = handle:read("*a") or ""
      handle:close()
      for line in result:gmatch("[^\n]+") do
        if line == name then return true end
      end
      return false
    end

    local function inside_tmux()
      return (os.getenv("TMUX") or "") ~= ""
    end

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

    local function echo(msg, hl)
      vim.api.nvim_echo({ { msg, hl or "Normal" } }, true, {})
    end

    math.randomseed(os.time() + (vim.fn.getpid and vim.fn.getpid() or 0))
    local function rand3()
      return string.format("%03d", math.random(0, 999))
    end

    local function send_to_iron(code)
      local ok, iron = pcall(require, "iron.core")
      if not ok then return false, "iron.core not available" end
      iron.send("python", code)
      return true
    end

    local function send_to_tmux_window(win_name, code)
      vim.fn.system({ "tmux", "load-buffer", "-" }, code)
      vim.fn.system({ "tmux", "paste-buffer", "-d", "-p", "-t", ":" .. win_name })
      vim.fn.system({ "tmux", "send-keys", "-t", ":" .. win_name, "Enter", "Enter" })
    end

    local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
    local source_py = script_dir .. "/f_visi_nvim_tool.py"

    vim.keymap.set("n", "Åv", function()
      local file = vim.api.nvim_buf_get_name(0)
      local ext = file:match("%.([^.]+)$")
      if ext ~= "py" then
        echo("needs to be .py", "WarningMsg")
        return
      end

      local word = vim.fn.expand("<cword>")
      if word == "" then
        echo("no word under cursor", "WarningMsg")
        return
      end

      local buf_dir = vim.fn.expand("%:p:h")
      local target_py = buf_dir .. "/f_visi_nvim_tool.py"
      if vim.fn.filereadable(target_py) == 0 then
        if vim.fn.filereadable(source_py) == 0 then
          echo("source missing: " .. source_py, "ErrorMsg")
          return
        end
        vim.fn.system({ "cp", source_py, target_py })
        if vim.v.shell_error ~= 0 then
          echo("cp failed: " .. source_py .. " -> " .. target_py, "ErrorMsg")
          return
        end
        echo("copied f_visi_nvim_tool.py -> " .. buf_dir, "MoreMsg")
      end

      local iron = check_iron_python_repl()
      local ipy_win = tmux_window_exists("ipyOut")

      local target
      if iron.running and iron.visible then
        target = "iron"
      elseif ipy_win then
        target = "tmux"
      else
        echo("no target: iron REPL not visible and no tmux window 'ipyOut'", "WarningMsg")
        return
      end

      if not inside_tmux() then
        echo("not inside tmux — cannot create the export window", "WarningMsg")
        return
      end

      local cwd = vim.fn.getcwd()
      local current_session = vim.fn.system({ "tmux", "display-message", "-p", "#S" }):gsub("%s+$", "")
      local vd_exists = tmux_has_session("vd")
      local target_session = vd_exists and "vd" or current_session

      local win_name = word .. "_" .. rand3()
      while tmux_window_exists(win_name) do
        win_name = word .. "_" .. rand3()
      end
      vim.fn.system({ "tmux", "new-window", "-t", target_session .. ":", "-n", win_name, "-c", cwd })

      local csv_abs = cwd .. "/" .. win_name .. ".csv"
      local code = string.format('f_visi_nvim_tool.export_to_csv(%s, "%s")', word, csv_abs)

      echo("=== visi_tmux_pane ===", "Title")
      echo("word: " .. word)
      echo("target session: " .. target_session .. (vd_exists and " (vd)" or " (current)"), "MoreMsg")
      echo("tmux window: " .. win_name, "MoreMsg")
      echo("repl target: " .. target .. "  (" .. iron.info .. ")")
      echo("send: " .. code, "MoreMsg")

      if target == "iron" then
        local ok, err = send_to_iron(code)
        if not ok then echo("iron send failed: " .. tostring(err), "ErrorMsg") end
      else
        send_to_tmux_window("ipyOut", code)
      end

      local q = vim.fn.shellescape(csv_abs)
      local shell_cmd = string.format(
        ". ./.venv/bin/activate; until [ -f %s ]; do sleep 0.2; done && vd %s; printf '\nPress Enter to delete file and close window...'; read -r _; rm -f %s; tmux kill-window",
        q, q, q
      )
      vim.fn.system({ "tmux", "send-keys", "-t", target_session .. ":" .. win_name, shell_cmd, "Enter" })
    end, { noremap = true, silent = false, desc = "visi: export <cword> to CSV and open in vd" })
  end,
}
-- ; rm -f %s; tmux kill-window
-- ". ./.venv/bin/activate; until [ -f \"%s\" ]; do sleep 0.2; done && vd \"%s\"; printf '\nPress Enter to delete file and close window...'; read -r _; rm -f \"%s\"; tmux kill-window"
