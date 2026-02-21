return {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v4.x',
  dependencies = {
    -- LSP Support
    { 'neovim/nvim-lspconfig' },
    { 'williamboman/mason.nvim' },
    { 'williamboman/mason-lspconfig.nvim' },

    -- Autocompletion
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'saadparwaiz1/cmp_luasnip' },
    { 'hrsh7th/cmp-nvim-lua' },

    -- Snippets
    { 'L3MON4D3/LuaSnip' },
    { 'rafamadriz/friendly-snippets' },
  },
  config = function()
    local lsp = require('lsp-zero')

    require('mason').setup({})
    require('mason-lspconfig').setup({
      ensure_installed = {
        'ts_ls',
        'lua_ls',
        'tailwindcss',
        'html',
        'cssls',
        'emmet_ls' },
      handlers = {
        function(server_name)
          require('lspconfig')[server_name].setup({})
        end,
        lua_ls = function()
          require('lspconfig').lua_ls.setup({
          })
        end,
      }
    })

    local cmp = require('cmp')
    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
      sources = {
        { name = 'lazydev', group_index = 0 },
        { name = 'copilot', group_index = 2 },
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'path' },
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
      })
    })
  end,
  keys = {
    { "gd",         function() vim.lsp.buf.definition() end,                           desc = "LSP Definition" },
    { "K",          function() vim.lsp.buf.hover() end,                                desc = "LSP Hover" },
    { "<leader>ls", function() vim.lsp.buf.workspace_symbol() end,                     desc = "LSP Workspace Symbol" },
    { "<leader>ld", function() vim.diagnostic.open_float() end,                        desc = "LSP Diagnostic Float" },
    { "]d",         function() vim.diagnostic.jump({ count = 1, float = false }) end,  desc = "Next Diagnostic" },
    { "[d",         function() vim.diagnostic.jump({ count = -1, float = false }) end, desc = "Prev Diagnostic" },
    { "<leader>la", function() vim.lsp.buf.code_action() end,                          desc = "LSP Code Action" },
    { "<leader>lr", function() vim.lsp.buf.references() end,                           desc = "LSP References" },
    { "<leader>lR", function() vim.lsp.buf.rename() end,                               desc = "LSP Rename" },
    { "<leader>lh", function() vim.lsp.buf.signature_help() end,                       desc = "LSP Signature Help" },
  },
}
