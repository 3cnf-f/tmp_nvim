local wezterm = require 'wezterm'

config.keys = {
  -- ... your other stuff ...
  {
    key = 'F12',  -- pick whatever key you like—F12's free usually
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SendString '   \n',
  },
}
