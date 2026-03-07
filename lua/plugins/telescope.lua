-- Fuzzy finder plugin, unified keymaps in keys field
return {
  'nvim-telescope/telescope.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>",                                                            desc = "Find Files" },
    { "<leader>fG", "<cmd>Telescope git_files<cr>",                                                             desc = "Find Git Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>",                                                             desc = "Live Grep" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>",                                                             desc = "Search Help" },
    { "<leader>fk", "<cmd>Telescope keymaps<cr>",                                                               desc = "Search Keymaps" },
    { "<leader>f*", "<cmd>Telescope grep_string<cr>",                                                           desc = "Search Current Word" },
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>",                                                           desc = "Search Diagnostics" },
    { "<leader>fo", "<cmd>Telescope oldfiles<cr>",                                                              desc = "Search Old Files" },
    { "<leader>fn", "<cmd>lua require('telescope.builtin').find_files({ cwd = vim.fn.stdpath('config') })<cr>", desc = "Search Neovim files" },
  },
  opts = {
    defaults = {
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--no-ignore",
        "--hidden",
      },
      mappings = {
        i = { ["<CR>"] = require("telescope.actions").select_drop },
        n = { ["<CR>"] = require("telescope.actions").select_drop },
      },
    },
    pickers = {
      find_files = {
        hidden = true,
        no_ignore = true,
      },
    },
  }
}
