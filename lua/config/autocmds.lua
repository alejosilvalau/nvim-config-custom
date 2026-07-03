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

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  pattern = "*",
  desc = "Clear rendered images when leaving buffer or focus",
  callback = function()
    local ok, image = pcall(require, "image")
    if ok then image.clear() end
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

-- Delete buffers that haven't been used recently when opening a new buffer
local max_buffers = 5
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    vim.schedule(function()
      local bufs = vim.fn.getbufinfo({ buflisted = 1 })
      if #bufs > max_buffers then
        table.sort(bufs, function(a, b) return a.lastused < b.lastused end)
        for i = 1, #bufs - max_buffers do
          local buf = bufs[i]
          if buf.changed == 0 then
            vim.api.nvim_buf_delete(buf.bufnr, {})
          end
        end
      end
    end)
  end,
})

-- Automatically generate spell files from .add files
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.add",
  callback = function()
    vim.cmd("mkspell! " .. vim.fn.expand("<afile>"))
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function(ev)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        vim.opt_local.signcolumn = "yes"
        require("netrw.ui").embelish(ev.buf)
        require("netrw.actions").bind(ev.buf)
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.md",
  callback = function()
    vim.keymap.set("n", "<leader>nc", function()
      local line = vim.api.nvim_get_current_line()
      if line:match("%- %[x%]") then
        vim.api.nvim_set_current_line((line:gsub("%- %[x%]", "- [ ]")))
      elseif line:match("%- %[ %]") then
        vim.api.nvim_set_current_line((line:gsub("%- %[ %]", "- [x]")))
      else
        local trimmed = line:match("^%s*%- (.+)")
        if trimmed then
          vim.api.nvim_set_current_line((line:gsub("^(%s*%- )", "%1[ ] ")))
        else
          vim.api.nvim_set_current_line((line:gsub("^(%s*)(.*)", "%1- [ ] %2")))
        end
      end
    end, { buffer = true, desc = "Toggle checkbox" })
  end,
})
