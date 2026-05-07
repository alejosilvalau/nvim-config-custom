return {
  "3rd/image.nvim",
  build = false,
  opts = {
    backend = "kitty",
    processor = "magick_cli",
    tmux_show_only_in_active_window = true,
    tmux_passthrough = true,
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = true,
        only_render_image_at_cursor = true,
        filetypes = { "markdown", "vimwiki" },
      },
    },
    window_overlap_clear_enabled = true,
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "notify", "netrw", "lazy" },
    editor_only_render_when_focused = true,
  },
  keys = {
    {
      "<leader>ic",
      function()
        local ok, image = pcall(require, "image")
        if ok then image.clear() end
      end,
      desc = "Clear rendered images",
    },
  },
}
