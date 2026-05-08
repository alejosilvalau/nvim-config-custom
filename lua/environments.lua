local base = {
  servers = { 'lua_ls', 'bashls' },
  formatters = {
    lua = { "stylua" },
    bash = { "shfmt" },
    sh = { "shfmt" },
  },
  parsers = {
    "lua", "bash", "vim", "vimdoc", "query",
    "markdown", "markdown_inline", "diff", "gitignore",
  }
}

local environments = {
  host = {
    servers = vim.list_extend(vim.deepcopy(base.servers),
      { 'ts_ls', 'tailwindcss', 'html', 'cssls', 'emmet_ls', 'sqlls', 'pyright' }),
    formatters = vim.tbl_deep_extend("force", base.formatters, {
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettierd", stop_after_first = true },
      json = { "prettierd", "prettierd", stop_after_first = true },
      python = { "black", "isort" },
      sql = { "sql_formatter" },
      mysql = { "sql_formatter" },
      xml = { "prettierd", "prettier", stop_after_first = true },
      dotenv = {},
    }),
    parsers = vim.list_extend(vim.deepcopy(base.parsers), {
      "javascript", "typescript", "jsdoc", "html", "css",
      "json", "xml", "sql", "python", "yaml", "toml",
      "dockerfile", "http",
    })
  },
  python = {
    servers = vim.list_extend(vim.deepcopy(base.servers), { 'pyright' }),
    formatters = vim.tbl_deep_extend("force", base.formatters, {
      python = { "black", "isort" },
    }),
    parsers = vim.list_extend(vim.deepcopy(base.parsers), {
      "python", "yaml", "toml", "dockerfile",
    })
  },
}

return environments.host
