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
  },
  config = function(_, opts)
    require("nvim-treesitter").setup(opts)

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(ev)
        local lang = ev.match

        -- Install the parser if it's not already installed
        vim.cmd("silent! TSInstall " .. lang)

        -- Start the highlighter
        pcall(vim.treesitter.start, ev.buf, lang)
      end,
    })
  end,
}
