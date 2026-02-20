return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ba", function() require("harpoon"):list():add() end,                                    mode = "n", desc = "Harpoon add" },
    { "<leader>bl", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, mode = "n", desc = "Harpoon quick menu" },
    { "<leader>1",  function() require("harpoon"):list():select(1) end,                                mode = "n", desc = "Harpoon select 1" },
    { "<leader>2",  function() require("harpoon"):list():select(2) end,                                mode = "n", desc = "Harpoon select 2" },
    { "<leader>3",  function() require("harpoon"):list():select(3) end,                                mode = "n", desc = "Harpoon select 3" },
    { "<leader>4",  function() require("harpoon"):list():select(4) end,                                mode = "n", desc = "Harpoon select 4" },
    { "<C-S-P>",    function() require("harpoon"):list():prev() end,                                   mode = "n", desc = "Harpoon previous buffer" },
    { "<C-S-N>",    function() require("harpoon"):list():next() end,                                   mode = "n", desc = "Harpoon next buffer" },
  },
}
