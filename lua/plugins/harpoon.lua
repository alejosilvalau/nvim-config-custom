return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({
      default = {
        display = function(list_item)
          local parts = vim.split(list_item.value, "/")
          local n = #parts
          if n == 1 then
            return list_item.value
          elseif n == 2 then
            return parts[n - 1] .. "/" .. parts[n]
          else
            return "../" .. parts[n - 1] .. "/" .. parts[n]
          end
        end,
      },
    })
  end,
  keys = {
    { "<leader>ba", function() require("harpoon"):list():add() end,                                    mode = "n", desc = "Harpoon add" },
    { "<leader>bl", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, mode = "n", desc = "Harpoon quick menu" },
    { "<leader>b1", function() require("harpoon"):list():select(1) end,                                mode = "n", desc = "Harpoon select 1" },
    { "<leader>b2", function() require("harpoon"):list():select(2) end,                                mode = "n", desc = "Harpoon select 2" },
    { "<leader>b3", function() require("harpoon"):list():select(3) end,                                mode = "n", desc = "Harpoon select 3" },
    { "<leader>b4", function() require("harpoon"):list():select(4) end,                                mode = "n", desc = "Harpoon select 4" },
    { "<leader>b5", function() require("harpoon"):list():select(5) end,                                mode = "n", desc = "Harpoon select 5" },
    { "<leader>b6", function() require("harpoon"):list():select(6) end,                                mode = "n", desc = "Harpoon select 6" },
    { "<leader>b7", function() require("harpoon"):list():select(7) end,                                mode = "n", desc = "Harpoon select 7" },
    { "<leader>b8", function() require("harpoon"):list():select(8) end,                                mode = "n", desc = "Harpoon select 8" },
    { "<leader>b9", function() require("harpoon"):list():select(9) end,                                mode = "n", desc = "Harpoon select 9" },
    { "<leader>b0", function() require("harpoon"):list():select(10) end,                               mode = "n", desc = "Harpoon select 10" },
    { "<leader>bo", function() require("harpoon"):list():prev() end,                                   mode = "n", desc = "Harpoon previous buffer" },
    { "<leader>bi", function() require("harpoon"):list():next() end,                                   mode = "n", desc = "Harpoon next buffer" },
  },
}
