-- local wezterm = require 'wezterm'
local platform = require('utils')
local config = {}


-- if platform.is_win then 
config.default_prog = { 'nu' }
-- end

return config
