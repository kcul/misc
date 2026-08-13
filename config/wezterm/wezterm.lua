-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- Brighten "bright black" (ANSI 8): shell autosuggestion ghost text uses it,
-- and the scheme's default is nearly invisible on the dark background.
local scheme = wezterm.get_builtin_color_schemes()['Monokai Dark (Gogh)']
scheme.brights[1] = '#8a8a8a'
config.color_schemes = {
  ['Monokai Dark (Gogh)'] = scheme,
}
config.color_scheme = 'Monokai Dark (Gogh)'
config.char_select_font_size = 20.0
config.command_palette_font_size = 20.0
config.font_size = 24.0
config.enable_tab_bar = true
config.window_decorations = "RESIZE"
config.initial_cols = 100
config.initial_rows = 28

-- and finally, return the configuration to wezterm
return config 
