return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = {
      enabled = true,
      auto_trigger = true,
      hide_during_completion = false,
      debounce = 50,
    },
    panel = { enabled = false },
  },
  keys = {
    {
      "<Tab>",
      function()
        local ok, copilot = pcall(require, "copilot.suggestion")
        if ok and copilot.is_visible() then
          copilot.accept()
        else
          return "<Tab>"
        end
      end,
      mode = "i",
      expr = true,
      remap = false,
      desc = "Accept Copilot suggestion or Tab",
    },
    { "<C-w>", function() require("copilot.suggestion").accept_word() end, mode = "i", desc = "Copilot accept word" },
    { "<C-l>", function() require("copilot.suggestion").accept_line() end, mode = "i", desc = "Copilot accept line" },
    { "<C-p>", function() require("copilot.suggestion").prev() end,        mode = "i", desc = "Copilot prev suggestion" },
    { "<C-n>", function() require("copilot.suggestion").next() end,        mode = "i", desc = "Copilot next suggestion" },
    { "<C-d>", function() require("copilot.suggestion").dismiss() end,     mode = "i", desc = "Copilot dismiss suggestion" },
  },
}
