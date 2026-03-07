return {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v4.x',
  dependencies = {
    -- LSP Support
    { 'neovim/nvim-lspconfig' },
    { 'williamboman/mason.nvim' },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'nvim-telescope/telescope.nvim' },

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
    local telescope = require('telescope.builtin')

    lsp.on_attach(function(client, bufnr)
      local map = function(keys, func, desc)
        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
      end

      -- This mapping is different since we want it to load when opening a file, not when the LSP attaches
      map("<leader>cd", function() telescope.lsp_definitions() end, "Code Definitions")
      map("<leader>ct", function() telescope.lsp_type_definitions() end, "Code Type Definitions")
      map("<leader>ci", function() telescope.lsp_implementations() end, "Code Implementations")
      map("D", function() vim.lsp.buf.hover() end, "Code Hover")
      map("<leader>cS", function() telescope.lsp_dynamic_workspace_symbols() end, "Code Workspace Symbols")
      map("<leader>cs", function() telescope.lsp_document_symbols() end, "Code Document Symbols")
      map("<leader>cD", function() vim.diagnostic.open_float() end, "Code Diagnostic Float")
      map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next Diagnostic")
      map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev Diagnostic")
      map("<leader>ca", function() vim.lsp.buf.code_action() end, "Code Action")
      map("<leader>cr", function() telescope.lsp_references() end, "Code References")
      map("<leader>cR", function() vim.lsp.buf.rename() end, "Code Rename")
      map("<leader>ch", function() vim.lsp.buf.signature_help() end, "Code Signature Help")
    end)

    require('mason').setup({})
    require('mason-lspconfig').setup({
      ensure_installed = {
        'ts_ls',
        'lua_ls',
        'tailwindcss',
        'html',
        'cssls',
        'emmet_ls',
        'bashls'
      },
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
