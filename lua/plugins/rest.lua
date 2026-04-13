return {
  "rest-nvim/rest.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, "http")
      table.insert(opts.ensure_installed, "json")
      table.insert(opts.ensure_installed, "xml")
      table.insert(opts.ensure_installed, "html")
    end,
  },
  keys = {
    { '<leader>cr', '<cmd>Rest run<CR>',  mode = 'n', desc = 'Run HTTP request under cursor' },
    { '<leader>cp', '<cmd>Rest open<CR>', mode = 'n', desc = 'Open rest.nvim result pane' },
    { '<leader>cl', '<cmd>Rest last<CR>', mode = 'n', desc = 'Repeat last HTTP request' },
  },
}
