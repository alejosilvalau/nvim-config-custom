config = function()  
	require("nvim-treesitter.configs").setup({
	    -- ... your existing config ...
	    ensure_installed = {
		"vimdoc",
		"help",
		"javascript",
		"typescript",
		"lua",
		"jsdoc",
		"bash",
	    },
	    sync_install = false,
	    auto_install = true,
	    indent = {
		enable = true,
	    },
	    highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	    },
	})
end
