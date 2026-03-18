return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    copilot_model = "gpt-41-copilot",
    suggestion = {
      enabled = true,
      auto_trigger = true,
      hide_during_completion = false,
      debounce = 0,
    },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      yaml = true,
      help = true,
      gitcommit = true,
      gitrebase = true,
      hgcommit = true,
      svn = true,
      cvs = true,
      ["."] = true,

    },
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
    { "<C-w>",   function() require("copilot.suggestion").accept_word() end, mode = "i", desc = "Accept word" },
    { "<C-M-l>", function() require("copilot.suggestion").accept_line() end, mode = "i", desc = "Accept line" },
    { "<C-p>",   function() require("copilot.suggestion").prev() end,        mode = "i", desc = "Prev suggestion" },
    { "<C-n>",   function() require("copilot.suggestion").next() end,        mode = "i", desc = "Next suggestion" },
    { "<C-d>",   function() require("copilot.suggestion").dismiss() end,     mode = "i", desc = "Dismiss suggestion" },
  },
}
