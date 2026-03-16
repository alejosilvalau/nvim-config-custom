return {
  "mbbill/undotree",
  keys = {
    { "<leader>u", "<cmd>UndotreeToggle<cr>", mode = "n", desc = "Toggle UndoTree" },
  },
  config = function()
    vim.opt.swapfile = false
    vim.opt.backup = false
    vim.opt.undodir = os.getenv('HOME') .. "/.vim/undodir"
    vim.opt.undofile = true
  end,
}
