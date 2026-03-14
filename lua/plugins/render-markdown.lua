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
}
