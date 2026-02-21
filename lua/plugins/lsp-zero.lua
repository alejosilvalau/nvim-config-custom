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

    lsp.on_attach(function(client, bufnr)
      local opts = { buffer = bufnr }

      -- This mapping is different since we want it to load when opening a file, not when the LSP attaches
      vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { buffer = bufnr, desc = "LSP Definition" })
      vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, { buffer = bufnr, desc = "LSP Hover" })
      vim.keymap.set("n", "<leader>ls", function() vim.lsp.buf.workspace_symbol() end,
        { buffer = bufnr, desc = "LSP Workspace Symbol" })
      vim.keymap.set("n", "<leader>ld", function() vim.diagnostic.open_float() end,
        { buffer = bufnr, desc = "LSP Diagnostic Float" })
      vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end,
        { buffer = bufnr, desc = "Next Diagnostic" })
      vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end,
        { buffer = bufnr, desc = "Prev Diagnostic" })
      vim.keymap.set("n", "<leader>la", function() vim.lsp.buf.code_action() end,
        { buffer = bufnr, desc = "LSP Code Action" })
      vim.keymap.set("n", "<leader>lr", function() vim.lsp.buf.references() end,
        { buffer = bufnr, desc = "LSP References" })
      vim.keymap.set("n", "<leader>lR", function() vim.lsp.buf.rename() end, { buffer = bufnr, desc = "LSP Rename" })
      vim.keymap.set("n", "<leader>lh", function() vim.lsp.buf.signature_help() end,
        { buffer = bufnr, desc = "LSP Signature Help" })
    end)

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
            settings = {
              Lua = {
                workspace = {
                  checkThirdParty = false,
                  maxPreload = 1000,
                  preloadFileSize = 150,
                },
                completion = {
                  workspaceWord = false,
                },
              }
            }
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
}
