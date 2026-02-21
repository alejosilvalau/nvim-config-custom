-- Automatic commands (e.g., trim whitespace on save)

--- Autoformat on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

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
