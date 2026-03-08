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

    lsp.on_attach(function(_, bufnr)
      local map = function(keys, func, desc)
        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
      end

      -- This mapping is different since we want it to load when opening a file, not when the LSP attaches
      map("<leader>cd", telescope.lsp_definitions, "Code Definitions")
      map("<leader>ct", telescope.lsp_type_definitions, "Code Type Definitions")
      map("<leader>ce", vim.lsp.buf.declaration, "Code Declarations")
      map("<leader>ci", telescope.lsp_implementations, "Code Implementations")
      map("D", vim.lsp.buf.hover, "Code Hover")
      map("<leader>cS", telescope.lsp_dynamic_workspace_symbols, "Code Workspace Symbols")
      map("<leader>cs", telescope.lsp_document_symbols, "Code Document Symbols")
      map("<leader>cD", vim.diagnostic.open_float, "Code Diagnostic Float")
      map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next Diagnostic")
      map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev Diagnostic")
      map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
      map("<leader>cr", telescope.lsp_references, "Code References")
      map("<leader>cR", vim.lsp.buf.rename, "Code Rename")
      map("<leader>ch", vim.lsp.buf.signature_help, "Code Signature Help")
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
