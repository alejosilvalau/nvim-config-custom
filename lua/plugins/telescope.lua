-- Fuzzy finder plugin, unified keymaps in keys field
return {
  'nvim-telescope/telescope.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Find files" },
    { "<leader>fG", "<cmd>Telescope git_files<cr>",   desc = "Find git files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Live grep" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>",   desc = "Search help" },
    { "<leader>fk", "<cmd>Telescope keymaps<cr>",     desc = "Search keymaps" },
    { "<leader>f*", "<cmd>Telescope grep_string<cr>", desc = "Search current word" },
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Search diagnostics" },
    { "<leader>fo", "<cmd>Telescope oldfiles<cr>",    desc = "Search old files" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>",     desc = "Search buffers" },
  },
  opts = {
    defaults = {
      file_ignore_patterns = {
        "worktrees/",
        "node_modules/",
        ".git/",
      },
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
        "--glob",
        "!.git/**",
        "--glob",
        "!worktrees/**",
        "--glob",
        "!node_modules/**",
      },
      mappings = {
        i = { ["<CR>"] = require("telescope.actions").select_default },
        n = { ["<CR>"] = require("telescope.actions").select_default },
      },
      path_display = { "smart" },
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
    end, { desc = "Search NeoVim files" })

    vim.keymap.set("n", "<leader>/", function()
      require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = "Fuzzily search buffer" })
  end,
}
