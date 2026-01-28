-- Fuzzy finder settings
return {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- optional but recommended
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    keys = {
   	 { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
	 { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
	 { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
	 { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
  },
}
