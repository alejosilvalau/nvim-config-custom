-- Automatic commands (e.g., trim whitespace on save)

-- Updates the working directory to the git root when entering a buffer
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local handle = io.popen('git -C ' .. vim.fn.expand('%:p:h') .. ' rev-parse --show-toplevel 2>/dev/null')
    local result = handle:read('*l')
    handle:close()
    if result then
      vim.fn.chdir(result)
    end
  end,
})

-- Highlight when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight on yank",
  group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
