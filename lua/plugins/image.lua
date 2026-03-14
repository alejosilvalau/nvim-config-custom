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
    editor_only_render_when_focused = true,
  },
  config = function(_, opts)
    local image = require("image")
    image.setup(opts)

    vim.api.nvim_create_autocmd("InsertEnter", {
      pattern = "*",
      callback = function()
        image.clear()
        vim.cmd("doautocmd CursorMoved")
      end,
    })
  end,
}
