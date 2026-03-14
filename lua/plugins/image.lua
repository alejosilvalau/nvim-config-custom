return {
  "3rd/image.nvim",
  build = false,
  opts = {
    processor = "magick_cli",
    -- Ghostty handles passthrough well, but it must be enabled here
    tmux_passthrough = true,
    integrations = {
      markdown = {
        enabled = true,
        only_render_image_at_cursor = true,
        filetypes = { "markdown", "vimwiki" },
      },
    },
    -- These should be set to true for the best experience in Ghostty/Tmux
    window_overlap_clear_enabled = true,
    editor_only_render_when_focused = true,
  },
}
