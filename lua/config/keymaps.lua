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
end, { desc = "File explorer" })

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

vim.keymap.set("n", "<leader>w", resize_mode, { desc = "Resize mode" })

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

-- Quickfix list navigation
vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>", { desc = "Previous quickfix item" })

vim.keymap.set("n", "<M-Down>", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
vim.keymap.set("n", "<M-Up>", "<cmd>cprev<CR>", { desc = "Previous quickfix item" })

vim.keymap.set("n", "<leader>lqo", "<cmd>copen<CR>", { desc = "Open quickfix list" })
vim.keymap.set("n", "<leader>lqc", "<cmd>cclose<CR>", { desc = "Close quickfix list" })

-- Location list navigation
vim.keymap.set("n", "<leader>lqj", "<cmd>lnext<CR>", { desc = "Next location item" })
vim.keymap.set("n", "<leader>lqk", "<cmd>lprev<CR>", { desc = "Previous location item" })

vim.keymap.set("n", "<leader>lqDown", "<cmd>lnext<CR>", { desc = "Next location item" })
vim.keymap.set("n", "<leader>lqUp", "<cmd>lprev<CR>", { desc = "Previous location item" })

vim.keymap.set("n", "<leader>llo", "<cmd>lopen<CR>", { desc = "Open location list" })
vim.keymap.set("n", "<leader>llc", "<cmd>lclose<CR>", { desc = "Close location list" })

-- Fix for vertical editing
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set({ "n" }, "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace word" })
vim.keymap.set({ "v" }, "<leader>rs", [[y:%s/<C-r>"/<C-r>"/gI<Left><Left><Left>]],
  { desc = "Replace selection" })

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make executable" })
