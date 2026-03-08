-- Fuzzy finder plugin, unified keymaps in keys field
return {
  'nvim-telescope/telescope.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Find Files" },
    { "<leader>fG", "<cmd>Telescope git_files<cr>",   desc = "Find Git Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Live Grep" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>",   desc = "Search Help" },
    { "<leader>fk", "<cmd>Telescope keymaps<cr>",     desc = "Search Keymaps" },
    { "<leader>f*", "<cmd>Telescope grep_string<cr>", desc = "Search Current Word" },
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Search Diagnostics" },
    { "<leader>fo", "<cmd>Telescope oldfiles<cr>",    desc = "Search Old Files" },
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
        i = { ["<CR>"] = require("telescope.actions").select_default },
        n = { ["<CR>"] = require("telescope.actions").select_default },
      },
    },
    pickers = {
      find_files = {
        hidden = true,
        no_ignore = true,
      },
    },
  },
  config = function(_, opts)
    require("telescope").setup(opts)
    require("telescope").load_extension("fzf")

    vim.keymap.set("n", "<leader>fn", function()
      require("telescope.builtin").find_files { cwd = vim.fn.stdpath "config" }
    end, { desc = "Search Neovim files" })

    vim.keymap.set("n", "<leader>/", function()
      require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = "Fuzzily search in current buffer" })
  end,
}
