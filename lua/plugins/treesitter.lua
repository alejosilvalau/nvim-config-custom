local env = require("environments")

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  opts = {
    ensure_installed = env.parsers,
  },
  config = function(_, opts)
    require("nvim-treesitter").setup(opts)
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(ev)
        local lang = ev.match
        if lang == "" then return end

        local known = pcall(vim.treesitter.language.inspect, lang)
        if not known then return end

        local ok = pcall(vim.treesitter.start, ev.buf, lang)
        if not ok then
          vim.notify("Treesitter: missing parser '" .. lang .. "', add it to environments.lua", vim.log.levels.WARN)
        end
      end,
    })
  end,
}
