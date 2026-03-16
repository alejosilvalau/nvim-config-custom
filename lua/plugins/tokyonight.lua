return
{
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night",
    transparent = true,
    styles = {
      sidebars = "border_highlight",
      floats = "border_highlight",
    },

    on_highlights = function(hl, c)
      -- Telescope
      hl.TelescopeNormal = { bg = c.bg_dark }
      hl.TelescopeBorder = { fg = c.border_highlight, bg = c.bg_dark }
      hl.TelescopePromptNormal = { bg = c.bg_dark }
      hl.TelescopePromptBorder = { fg = c.border_highlight, bg = c.bg_dark }
      hl.TelescopePromptTitle = { fg = c.border_highlight, bg = c.bg_dark }
      hl.TelescopePreviewNormal = { bg = c.bg_dark }
      hl.TelescopePreviewBorder = { fg = c.border_highlight, bg = c.bg_dark }
      hl.TelescopePreviewTitle = { fg = c.border_highlight, bg = c.bg_dark }
      hl.TelescopeResultsNormal = { bg = c.bg_dark }
      hl.TelescopeResultsBorder = { fg = c.border_highlight, bg = c.bg_dark }
      hl.TelescopeResultsTitle = { fg = c.border_highlight, bg = c.bg_dark }

      -- Snacks picker
      hl.SnacksPickerNormal = { bg = c.bg_dark }
      hl.SnacksPickerBorder = { fg = c.border_highlight, bg = c.bg_dark }
      hl.SnacksPickerInputNormal = { bg = c.bg_dark }
      hl.SnacksPickerInputBorder = { fg = c.border_highlight, bg = c.bg_dark }
      hl.SnacksPickerPreviewNormal = { bg = c.bg_dark }
      hl.SnacksPickerPreviewBorder = { fg = c.border_highlight, bg = c.bg_dark }

      -- Snacks input
      hl.SnacksInputNormal = { bg = c.bg_dark }
      hl.SnacksInputBorder = { fg = c.border_highlight, bg = c.bg_dark }

      -- Avante
      hl.AvanteSidebarNormal = { bg = "NONE", fg = c.fg }
      hl.AvanteSidebarWinSeparator = { fg = c.bg_dark }

      -- General floats (covers anything else like LSP hover, diagnostics, etc.)
      hl.WinSeparator = { fg = c.bg_dark }
      hl.NormalFloat = { bg = c.bg_dark }
      hl.FloatBorder = { fg = c.border_highlight, bg = c.bg_dark }

      -- Which-key
      hl.WhichKeyNormal = { bg = c.bg_dark }
      hl.WhichKeyBorder = { fg = c.border_highlight, bg = c.bg_dark }
    end,
  },
  init = function()
    vim.cmd([[colorscheme tokyonight]])
  end,
}
