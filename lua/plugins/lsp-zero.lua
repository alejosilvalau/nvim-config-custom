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
    local luasnip = require('luasnip')
    require('luasnip.loaders.from_vscode').lazy_load()

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

      if client.name == "ltex_plus" then
        map("<leader>le", function()
          client.config.settings.ltex.language = "en-US"
          client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
        end, "LTeX: switch to English")

        map("<leader>ls", function()
          client.config.settings.ltex.language = "es"
          client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
        end, "LTeX: switch to Spanish")
      end
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
        'bashls',
        'ltex_plus'
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
        ltex_plus = function()
          print("ltex_plus handler running")
          require('lspconfig').ltex_plus.setup({
            settings = {
              ltex = {
                language = "en-US",
                additionalRules = {
                  enablePickyRules = false,
                },
                disabledRules = {
                  ["en-US"] = { "WHITESPACE_RULE" },
                  ["es"] = { "WHITESPACE_RULE" },
                },
              },
            },
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
        { name = 'luasnip' },
        { name = 'nvim_lua' },
        { name = 'buffer' },
        { name = 'path' },
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-l>'] = cmp.mapping(function()
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          end
        end, { 'i', 's' }),
        ['<C-h>'] = cmp.mapping(function()
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { 'i', 's' }),
      })
    })
  end,
}
