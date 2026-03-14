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
  },
}
