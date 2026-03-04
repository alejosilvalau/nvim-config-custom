return {
  'MagicDuck/grug-far.nvim',
  keys = {
    { "<leader>fr", "<cmd>GrugFar<cr>", desc = "Find and Replace" },
  },
  opts = {
    engines = {
      ripgrep = {
        extraArgs = "--no-ignore --hidden",
      },
    },
  }
}
