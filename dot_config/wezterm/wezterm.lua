local wezterm = require 'wezterm'
local platform = require('utils')
local act = wezterm.action
local config = {}

config.default_prog = { 'nu' }
if platform.is_win then 
config.keys = {{ key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },}
end

return config
