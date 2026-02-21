return {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v4.x',
  dependencies = {
    -- LSP Support
    {'neovim/nvim-lspconfig'},             
    {'williamboman/mason.nvim'},           
    {'williamboman/mason-lspconfig.nvim'}, 

    -- Autocompletion
    {'hrsh7th/nvim-cmp'},         
    {'hrsh7th/cmp-nvim-lsp'},     
    {'hrsh7th/cmp-buffer'},       
    {'hrsh7th/cmp-path'},         
    {'saadparwaiz1/cmp_luasnip'}, 
    {'hrsh7th/cmp-nvim-lua'},     

    -- Snippets
    {'L3MON4D3/LuaSnip'},             
    {'rafamadriz/friendly-snippets'}, 
  },
  config = function()
    local lsp = require('lsp-zero')

    require('mason').setup({})
    require('mason-lspconfig').setup({
      ensure_installed = { 'ts_ls', 'lua_ls', 'tailwindcss' },
      handlers = {
        function(server_name)
          require('lspconfig')[server_name].setup({})
        end,
      }
    })

    local cmp = require('cmp')
    cmp.setup({
      sources = { { name = 'nvim_lsp' }, { name = 'buffer' } },
      mapping = cmp.mapping.preset.insert({
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
      })
    })
  end,
  keys = {
        { "gd",         function() vim.lsp.buf.definition() end,       desc = "LSP Definition" },
    { "K",          function() vim.lsp.buf.hover() end,            desc = "LSP Hover" },
    { "<leader>ls", function() vim.lsp.buf.workspace_symbol() end, desc = "LSP Workspace Symbol" },
    { "<leader>ld", function() vim.diagnostic.open_float() end,    desc = "LSP Diagnostic Float" },
    { "]d",         function() vim.diagnostic.goto_next() end,     desc = "Next Diagnostic" },
    { "[d",         function() vim.diagnostic.goto_prev() end,     desc = "Prev Diagnostic" },
    { "<leader>la", function() vim.lsp.buf.code_action() end,      desc = "LSP Code Action" },
    { "<leader>lr", function() vim.lsp.buf.references() end,       desc = "LSP References" },
    { "<leader>lR", function() vim.lsp.buf.rename() end,           desc = "LSP Rename" },
    { "<leader>lh", function() vim.lsp.buf.signature_help() end,   desc = "LSP Signature Help" },
  },
}
