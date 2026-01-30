return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local status, configs = pcall(require, "nvim-treesitter.configs")
        if not status then
	    print("Failed to load treesitter configs")
            return
        end

        configs.setup({
            ensure_installed = {
		"help",
                "vimdoc",
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
    end,
}
