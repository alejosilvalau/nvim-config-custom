return {
  "rest-nvim/rest.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, "http")
    end,
  },
  keys = {
    { '<leader>cr', '<cmd>RestNvim<CR>',        mode = 'n', desc = 'Run HTTP request under cursor' },
    { '<leader>cp', '<cmd>RestNvimPreview<CR>', mode = 'n', desc = 'Preview HTTP request' },
    { '<leader>cl', '<cmd>RestNvimLast<CR>',    mode = 'n', desc = 'Repeat last HTTP request' },
  }
}
