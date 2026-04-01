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
    instructions_file = "AGENTS.md",
    provider = "copilot",
    behaviour = {
      auto_suggestions = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
      auto_approve_tool_permissions = false,
      confirmation_ui_style = "popup",
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
    "HakonHarnes/img-clip.nvim",
  },
  keys = {
    { "<leader>aa", function() require("avante.api").ask() end,     mode = { "n", "v" }, desc = "Avante: ask" },
    { "<leader>ar", function() require("avante.api").refresh() end, mode = "n",          desc = "Avante: refresh" },
    { "<leader>ae", function() require("avante.api").edit() end,    mode = "n",          desc = "Avante: edit" },
    { "<leader>at", "<cmd>AvanteToggle<cr>",                        mode = "n",          desc = "Avante: toggle" },
    { "<leader>an", "<cmd>AvanteChatNew<cr>",                       mode = "n",          desc = "Avante: new chat" },
    { "<leader>af", "<cmd>AvanteFocus<cr>",                         mode = "n",          desc = "Avante: focus" },
    { "<leader>ah", "<cmd>AvanteHistory<cr>",                       mode = "n",          desc = "Avante: history" },
    { "<leader>aS", "<cmd>AvanteStop<cr>",                          mode = "n",          desc = "Avante: stop" },
    { "<leader>aC", "<cmd>AvanteClear<cr>",                         mode = "n",          desc = "Avante: clear" },
    { "<leader>aP", "<cmd>AvanteSwitchProvider<cr>",                mode = "n",          desc = "Avante: switch provider" },
    { "<leader>aM", "<cmd>AvanteSwitchInputProvider<cr>",           mode = "n",          desc = "Avante: switch input provider" },
  },

}
