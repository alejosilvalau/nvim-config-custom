return {
  "benlubas/molten-nvim",
  version = "^1.0.0",
  build = ":UpdateRemotePlugins",
  init = function()
    vim.g.molten_output_win_max_height = 12
    vim.g.molten_auto_open_output = true
    vim.g.molten_auto_update_output = true
    vim.g.molten_image_provider = "image.nvim"
  end,
  config = function()
    vim.api.nvim_create_user_command("JupytextToMarkdown", function()
      local file = vim.fn.expand("%:p")
      local out = file:gsub("%.ipynb$", ".md")
      vim.fn.system("jupytext --to markdown '" .. file .. "'")
      vim.notify("Converted to: " .. out)
    end, {})

    vim.api.nvim_create_user_command("JupytextSync", function()
      local file = vim.fn.expand("%:p")
      vim.fn.system({ "jupytext", "--sync", file })
      vim.notify("Synced: " .. file)
    end, {})
  end,
  keys = {
    -- Kernel
    { "<leader>cmi", "<cmd>MoltenInit<cr>",             desc = "Init kernel" },
    { "<leader>cmq", "<cmd>MoltenDeinit<cr>",           desc = "Quit kernel" },
    { "<leader>cmr", "<cmd>MoltenRestart<cr>",          desc = "Restart kernel" },
    { "<leader>cmx", "<cmd>MoltenInterrupt<cr>",        desc = "Interrupt kernel" },
    { "<leader>cmI", "<cmd>MoltenInfo<cr>",             desc = "Kernel info" },
    -- Evaluate
    { "<leader>cme", "<cmd>MoltenEvaluateOperator<cr>", desc = "Evaluate cell",        mode = { "n" } },
    { "<leader>cme", ":<C-u>MoltenEvaluateVisual<cr>",  desc = "Evaluate selection",   mode = { "v" } },
    { "<leader>cml", "<cmd>MoltenEvaluateLine<cr>",     desc = "Evaluate line" },
    { "<leader>cmE", "<cmd>MoltenReevaluateCell<cr>",   desc = "Re-evaluate cell" },
    { "<leader>cmR", "<cmd>MoltenReevaluateAll<cr>",    desc = "Re-evaluate all" },
    { "<leader>cmd", "<cmd>MoltenDelete<cr>",           desc = "Delete cell" },
    -- Navigate
    { "<leader>cmn", "<cmd>MoltenNext<cr>",             desc = "Next cell" },
    { "<leader>cmp", "<cmd>MoltenPrev<cr>",             desc = "Prev cell" },
    { "<leader>cmg", "<cmd>MoltenGoto<cr>",             desc = "Goto cell" },
    -- Output
    { "<leader>cmo", "<cmd>MoltenToggleOutput<cr>",     desc = "Toggle output" },
    { "<leader>cms", "<cmd>MoltenShowOutput<cr>",       desc = "Show output" },
    { "<leader>cmh", "<cmd>MoltenHideOutput<cr>",       desc = "Hide output" },
    { "<leader>cmb", "<cmd>MoltenOpenInBrowser<cr>",    desc = "Open in browser" },
    -- Save / Load
    { "<leader>cmw", "<cmd>MoltenSave<cr>",             desc = "Write/save output" },
    { "<leader>cmL", "<cmd>MoltenLoad<cr>",             desc = "Load output" },
    { "<leader>cmP", "<cmd>MoltenExportOutput<cr>",     desc = "Export output" },
    { "<leader>cmO", "<cmd>MoltenImportOutput<cr>",     desc = "Import output" },
    -- Misc
    { "<leader>cmm", "<cmd>JupytextToMarkdown<cr>",     desc = "Convert to Markdown" },
    { "<leader>cms", "<cmd>JupytextSync<cr>",           desc = "Sync notebook" },
    { "<leader>cmu", "<cmd>UpdateRemotePlugins<cr>",    desc = "Update remote plugins" },
  },
}
