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
			sidebars = "border_highlight", 
			floats = "border_highlight",   
		},

		on_highlights = function(hl, c) 
			hl.TelescopeBorder = {
				fg = c.border_highlight, 
			}
			hl.FloatBorder = {
				fg = c.border_highlight, 
			}
		end,
	},
}
