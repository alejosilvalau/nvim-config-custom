return {
  "olimorris/codecompanion.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
    "stevearc/dressing.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "echasnovski/mini.diff",
      config = function()
        require("mini.diff").setup()
      end,
    },
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
  },
  opts = {
    adapters = {
      copilot = function()
        return require("codecompanion.adapters").extend("copilot", {
          schema = {
            model = {
              default = "gpt-4o-2024-05-13",
            },
          },
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "copilot",
      },
      inline = {
        adapter = "copilot",
      },
      agent = {
        adapter = "copilot",
      },
    },
    opts = {
      log_level = "ERROR",
    },
    display = {
      chat = {
        window = {
          position = "right",
        },
      },
      diff = {
        provider = "mini_diff",
      },
    },
  },
  keys = {
    { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion: toggle chat" },
    { "<leader>an", "<cmd>CodeCompanionChat<cr>",        mode = { "n", "v" }, desc = "CodeCompanion: new chat" },
    { "<leader>as", "<cmd>CodeCompanionChat Add<cr>",    mode = "v",          desc = "CodeCompanion: add to chat" },
    { "<leader>ai", "<cmd>CodeCompanion<cr>",            mode = { "n", "v" }, desc = "CodeCompanion: inline assist" },
    { "<leader>aa", "<cmd>CodeCompanionActions<cr>",     mode = { "n", "v" }, desc = "CodeCompanion: actions" },
  },
}
