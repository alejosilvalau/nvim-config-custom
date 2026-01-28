-- Statusline, themes, etc.
return 
{
	"folke/tokyonight.nvim",
	lazy = false,    
	priority = 1000, 
	opts = {
		style = "night", 
		transparent = true, 
		styles = {
			sidebars = "transparent", -- Sets sidebar background to transparent
			floats = "transparent",   -- Sets floating windows background to transparent
		},

		on_highlights = function(hl, c) 
			hl.TelescopeBorder = {
				fg = c.border_highlight, -- Uses the theme's highlight color for the border
			}
			hl.FloatBorder = {
				fg = c.border_highlight, -- Ensures floating window borders stay visible
			}
		end,
	},
	config = function(_, opts)
		local tokyonight = require("tokyonight")
		tokyonight.setup(opts) 
		tokyonight.load()     
	end,
}
