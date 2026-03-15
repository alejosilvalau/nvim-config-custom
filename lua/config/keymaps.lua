-- Custom shortcuts
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "<leader>e", function()
  -- Clear all rendered images first
  local ok, image = pcall(require, "image")
  if ok then
    image.clear()
  end

  -- Close floating windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  vim.cmd.Ex()
end, { desc = "Open file explorer" })

-- Window resizing (enter resize mode with <leader>wr, then use +/-/</>  to resize, q or <Esc> to exit)
local function resize_mode()
  print("Resize mode: + - < > (q/<Esc> to exit)")
  while true do
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then break end
    if key == "+" then
      vim.cmd("resize +2")
    elseif key == "-" then
      vim.cmd("resize -2")
    elseif key == "<" then
      vim.cmd("vertical resize -2")
    elseif key == ">" then
      vim.cmd("vertical resize +2")
    elseif key == "=" then
      vim.cmd("wincmd =")
    elseif key == "q" or key == "\27" then
      break -- \27 = Esc
    end
    vim.cmd("redraw")
  end
  print("Resize mode exited")
end

vim.keymap.set("n", "<leader>wr", resize_mode, { desc = "Enter resize mode" })


-- Move selected code
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Cursor movement
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })
vim.keymap.set({ "n", "x" }, "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set({ "n", "x" }, "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result and center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result and center" })

vim.keymap.set("n", "<leader><leader>", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- Fix for vertical editing
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format buffer with LSP" })

vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Search and replace word under cursor" })

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make current file executable" })

-- Toggle markdown checkboxes
vim.keymap.set("n", "<leader>nc", function()
  local line = vim.api.nvim_get_current_line()
  if line:match("%- %[x%]") then
    vim.api.nvim_set_current_line((line:gsub("%- %[x%]", "- [ ]")))
  elseif line:match("%- %[ %]") then
    vim.api.nvim_set_current_line((line:gsub("%- %[ %]", "- [x]")))
  else
    -- no checkbox structure, create one
    local trimmed = line:match("^%s*%- (.+)") -- already a list item
    if trimmed then
      vim.api.nvim_set_current_line((line:gsub("^(%s*%- )", "%1[ ] ")))
    else
      -- not a list item, wrap the whole line
      vim.api.nvim_set_current_line((line:gsub("^(%s*)(.*)", "%1- [ ] %2")))
    end
  end
end, { buffer = true, desc = "Toggle checkbox" })

-- Fast fix: pick the first suggestion for the word under cursor
vim.keymap.set("n", "<leader>nf", "1z=", { desc = "Spell Fix (First suggestion)" })
