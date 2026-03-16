local user = vim.fn.expand("$USER")
local media = "/media/" .. user

local vaults = {
  alnix404   = media .. "/Archive/AlnixDev/vault-alnix404",
  alnixdev   = media .. "/Archive/AlnixDev/vault-alnixdev",
  university = media .. "/Archive/Job/vault-university",
  personal   = media .. "/Archive/Personal/vault-personal",
  desktop    = vim.fn.expand("~") .. "/Desktop/vault-desktop",
}

local events = {}
for _, path in pairs(vaults) do
  table.insert(events, "BufReadPre " .. path .. "/*.md")
  table.insert(events, "BufNewFile " .. path .. "/*.md")
end

return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  event = events,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      { name = "alnix404",   path = vaults.alnix404 },
      { name = "alnixdev",   path = vaults.alnixdev },
      { name = "university", path = vaults.university },
      { name = "personal",   path = vaults.personal },
      { name = "desktop",    path = vaults.desktop },
    },
    ui = {
      enable = false
    },
    note_frontmatter_func = function(note)
      return {
        date    = os.date("%Y-%m-%d"),
        aliases = note.aliases or {},
        tags    = note.tags or {},
      }
    end,
  },
  -- Checkbox toggle
  config = function(_, opts)
    require("obsidian").setup(opts)
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*.md",
      callback = function()
        local ok, obsidian = pcall(require, "obsidian")
        if not ok then return end
        if obsidian.get_client() == nil then return end

        vim.keymap.set("n", "<leader>no", ":ObsidianTemplate note<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>",
          { desc = "Apply note template" })

        vim.keymap.set("n", "<leader>nt", "<cmd>ObsidianTags<cr>", { desc = "Search Tags" })

        vim.keymap.set("n", "<leader>ns", function()
          return require("obsidian").util.smart_action()
        end, { buffer = true, expr = true, desc = "Smart action" })
      end,
    })
  end,
}
