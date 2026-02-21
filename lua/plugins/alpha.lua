return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local dashboard = require("alpha.themes.dashboard")

    dashboard.section.header.val = {
      "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗  ",
      "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║  ",
      "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║  ",
      "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║  ",
      "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║  ",
      "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝  ",
    }

    dashboard.section.buttons.val = {
      dashboard.button("e", "  New file", "<cmd>ene <BAR> startinsert<CR>"),
      dashboard.button("f", "  Find file", "<cmd>Telescope find_files<CR>"),
      dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<CR>"),
      dashboard.button("g", "  Live grep", "<cmd>Telescope live_grep<CR>"),
      dashboard.button("c", "  Config", "<cmd>e $MYVIMRC<CR>"),
      dashboard.button("q", "  Quit", "<cmd>qa<CR>"),
    }

    local plugins = require("lazy").stats().count
    dashboard.section.footer.val = "⚡ " .. plugins .. " plugins loaded"

    dashboard.config.layout = {
      { type = "padding", val = vim.fn.max({ 2, vim.fn.floor(vim.fn.winheight(0) / 4) }) },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      { type = "padding", val = 1 },
      dashboard.section.footer,
    }

    require("alpha").setup(dashboard.config)
  end,
}
