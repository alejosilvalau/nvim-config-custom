return {
  "yetone/avante.nvim",
  build = vim.fn.has("win32") ~= 0
      and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
  event = "VeryLazy",
  version = false,
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    instructions_file = "avante.md",
    provider = "copilot",
    auto_suggestions_provider = "copilot",
    behaviour = {
      auto_suggestions = true,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
      auto_approve_tool_permissions = false,
      confirmation_ui_style = "inline_buttons",
    },
    providers = {
      copilot = {
        endpoint = "https://api.githubcopilot.com",
        model = "gpt-4o-2024-05-13",
        timeout = 30000,
        temperature = 0,
        extra_request_body = {
          max_tokens = 4096,
        }
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-telescope/telescope.nvim",
    "hrsh7th/nvim-cmp",
    "stevearc/dressing.nvim",
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
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
}
