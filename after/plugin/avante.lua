local keymap = vim.keymap

keymap.set("n", "<leader>aa", function() require("avante.api").ask() end, { desc = "avante: ask" })
keymap.set("v", "<leader>aa", function() require("avante.api").ask() end, { desc = "avante: ask" })
keymap.set("n", "<leader>ar", function() require("avante.api").refresh() end, { desc = "avante: refresh" })
keymap.set("n", "<leader>ae", function() require("avante.api").edit() end, { desc = "avante: edit" })
