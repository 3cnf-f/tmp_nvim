local wezterm = require 'wezterm'
local config = {}
config.color_scheme = 'Gruvbox Material (Gogh)'


-- =========================================================
-- THE FIX: Tell WezTerm to send "Esc" + key instead of "Text"
-- =========================================================
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Optional: If you use Mac, this ensures Option acts as Alt (Meta)
config.use_ime = true 
config.font = wezterm.font('JetBrainsMonoNL Nerd Font')

config.font_size = 16


return config
