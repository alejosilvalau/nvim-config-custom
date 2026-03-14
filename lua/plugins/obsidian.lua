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
  -- Checkbox toggle
  config = function(_, opts)
    require("obsidian").setup(opts)

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*.md",
      callback = function()
        local ok, obsidian = pcall(require, "obsidian")
        if not ok then return end
        if obsidian.get_client() == nil then return end

        vim.keymap.set("n", "<M-CR>", function()
          local line = vim.api.nvim_get_current_line()
          if line:match("%- %[x%]") then
            vim.api.nvim_set_current_line((line:gsub("%- %[x%]", "- [ ]")))
          elseif line:match("%- %[ %]") then
            vim.api.nvim_set_current_line((line:gsub("%- %[ %]", "- [x]")))
          else
            -- no checkbox structure, create one
            local trimmed = line:match("^%s*%- (.+)") -- already a list item
            if trimmed then
              vim.api.nvim_set_current_line((line:gsub("^(%s*%- )", "%1[ ] ")))
            else
              -- not a list item, wrap the whole line
              vim.api.nvim_set_current_line((line:gsub("^(%s*)(.*)", "%1- [ ] %2")))
            end
          end
        end, { buffer = true, desc = "Toggle checkbox" })
      end,
    })
  end,
}
