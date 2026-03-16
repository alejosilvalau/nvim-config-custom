return {
  'williamboman/mason.nvim',
  dependencies = {
    { 'williamboman/mason-lspconfig.nvim' },
    { 'neovim/nvim-lspconfig' },
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
    local telescope = require('telescope.builtin')
    local luasnip = require('luasnip')
    require('luasnip.loaders.from_vscode').lazy_load()

    -- Native LspAttach replaces lsp.on_attach
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
        end

        -- Navigation
        map("gd", telescope.lsp_definitions, "Go to definition")
        map("grr", telescope.lsp_references, "Go to references")
        map("gri", telescope.lsp_implementations, "Go to implementations")
        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("grt", telescope.lsp_type_definitions, "Go to type definition")

        -- Documentation
        map("K", vim.lsp.buf.hover, "Documentation hover")
        map("<C-k>", vim.lsp.buf.signature_help, "Signature help")

        map("gl", vim.diagnostic.setloclist, "Show diagnostics in location list")
        map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
        map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev diagnostic")

        -- Action
        map("gra", vim.lsp.buf.code_action, "Code action")
        map("grn", vim.lsp.buf.rename, "Rename symbol")

        -- Telescope LSP symbols
        map("go", telescope.lsp_dynamic_workspace_symbols, "Code workspace symbols")
        map("gO", telescope.lsp_document_symbols, "Code document symbols")
      end
    })

    -- Custom server configs
    vim.lsp.config('lua_ls', {
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

    require('mason').setup({})
    require('mason-lspconfig').setup({
      ensure_installed = {
        'ts_ls', 'lua_ls', 'tailwindcss', 'html',
        'cssls', 'emmet_ls', 'bashls'
      },
    })

    for _, server_name in ipairs(require('mason-lspconfig').get_installed_servers()) do
      vim.lsp.enable(server_name)
    end

    -- Autocompletion
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
