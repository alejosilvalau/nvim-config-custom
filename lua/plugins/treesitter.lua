return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  opts = {
    ensure_installed = {
      "vimdoc",
      "javascript",
      "typescript",
      "lua",
      "jsdoc",
      "bash",
      "html",
      "css",
    },
    sync_install = false,
    auto_install = true,
    indent = {
      enable = true,
    },
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
  },
}
