return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    heading = {
      position = "inline",
      icons = { "➊  ", "➋  ", "➌  ", "➍  ", "➎  ", "➏  " },
      match_only_hash_headings = "true",
    },
    indent = {
      enabled = true,
      -- This adds 2 spaces of indentation per heading level
      per_level = 2,
      -- If true, it skips indenting H1 and only starts from H2 onwards
      skip_level = 1,
    },
    render_modes = true,
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    vim.api.nvim_set_hl(0, "markdownTag", { fg = "#7dcfff", italic = true })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        vim.fn.matchadd("markdownTag", "#\\w\\+")
      end,
    })
  end,
}
