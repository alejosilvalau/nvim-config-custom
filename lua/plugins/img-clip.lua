return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      embed_image_as_base64 = false,
      prompt_for_file_name = false,
      drag_and_drop = {
        insert_mode = true,
      },
      use_absolute_path = false,
      relative_to_current_file = true,
      dir_path = ".",
    },
  },
  keys = {
    { "<leader>ip", "<cmd>PasteImage<cr>", mode = "n", desc = "Paste image from clipboard" },
  },
}
