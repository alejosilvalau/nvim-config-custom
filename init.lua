vim.opt.runtimepath:prepend(vim.fn.stdpath('data') .. '/site')

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
