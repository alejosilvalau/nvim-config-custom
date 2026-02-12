vim.keymap.set("i", "<Tab>", function()
  local ok, copilot = pcall(require, "copilot.suggestion")
  if ok and copilot.is_visible() then
    copilot.accept()
  else
    return "<Tab>"
  end
end, { expr = true, remap = false, desc = "Accept Copilot suggestion or Tab" })

vim.keymap.set("i", "<C-w>", function()
  require("copilot.suggestion").accept_word()
end, { desc = "Copilot accept word" })

vim.keymap.set("i", "<C-l>", function()
  require("copilot.suggestion").accept_line()
end, { desc = "Copilot accept line" })

vim.keymap.set("i", "<C-p>", function()
  require("copilot.suggestion").prev()
end, { desc = "Copilot prev suggestion" })

vim.keymap.set("i", "<C-n>", function()
  require("copilot.suggestion").next()
end, { desc = "Copilot next suggestion" })

vim.keymap.set("i", "<C-d>", function()
  require("copilot.suggestion").dismiss()
end, { desc = "Copilot dismiss suggestion" })
