-- Automatic commands (e.g., trim whitespace on save)

-- Updates the working directory to the git root when entering a buffer
vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Change working directory to git root",
  group = vim.api.nvim_create_augroup("GitRootDirectory", { clear = true }),
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

-- Delete unmodified buffers when leaving them
vim.api.nvim_create_autocmd("BufLeave", {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype == "" and not vim.bo[buf].modified then
      vim.schedule(function()
        vim.api.nvim_buf_delete(buf, {})
      end)
    end
  end,
})
