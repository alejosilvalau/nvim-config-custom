-- Custom shortcuts
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "<leader>e", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  vim.cmd.Ex()
end, { desc = "Open file explorer" })

-- Window navigation
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Move to down window" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Move to up window" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Move to right window" })

-- Window splitting
vim.keymap.set("n", "<leader>ws", "<C-w>s", { desc = "Split window horizontally" })
vim.keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" })

-- Window closing
vim.keymap.set("n", "<leader>wq", "<C-w>q", { desc = "Close window" })
vim.keymap.set("n", "<leader>wo", "<C-w>o", { desc = "Close other windows" })

-- Window resizing
vim.keymap.set("n", "<leader>w=", "<C-w>=", { desc = "Equal window sizes" })
vim.keymap.set("n", "<leader>w-", "<C-w>-", { desc = "Decrease height" })
vim.keymap.set("n", "<leader>w+", "<C-w>+", { desc = "Increase height" })
vim.keymap.set("n", "<leader>w<", "<C-w><", { desc = "Decrease width" })
vim.keymap.set("n", "<leader>w>", "<C-w>>", { desc = "Increase width" })

-- Move selected code
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- System clipboard integration
vim.keymap.set({ "n", "v" }, "<leader>ys", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>yl", [["+Y]], { desc = "Yank line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>pa", [["+p]], { desc = "Paste from system clipboard after the cursor" })
vim.keymap.set("n", "<leader>pb", [["+P]], { desc = "Paste before cursor from system clipboard before the cursor" })
vim.keymap.set("v", "<leader>ps", '"_dp', { desc = "Paste without overwriting register" })
vim.keymap.set({ "v", "n" }, "<leader>ds", '"_d', { desc = "Delete without overwriting register" })

-- Cursor movement
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result and center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- Fix for vertical editing
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format buffer with LSP" })

vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Search and replace word under cursor" })

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true }, { desc = "Make current file executable" })
