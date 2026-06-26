return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    preset = 'helix', -- 'default', 'modern', or 'helix'
    delay = 300,
    icons = {
      mappings = true, -- shows icons next to keymaps
      keys = {
        Space = '󱁐',
      },
    },
    spec = {
      { '<leader>a',   group = 'AI',           mode = { 'n', 'v' } },
      { '<leader>b',   group = 'Buffers',      mode = { 'n', 'v' } },
      { '<leader>d',   group = 'Debug',        mode = { 'n', 'v' } },
      { '<leader>f',   group = 'Find',         mode = { 'n', 'v' } },
      { '<leader>j',   group = 'Java',         mode = { 'n', 'v' } },
      { '<leader>jt',  group = 'Java tests',   mode = { 'n', 'v' } },
      { '<leader>je',  group = 'Java extract', mode = { 'n', 'v' } },
      { '<leader>jS',  group = 'Java source',  mode = { 'n', 'v' } },
      { '<leader>jL',  group = 'Java library', mode = { 'n', 'v' } },
      { '<leader>n',   group = 'Notes',        mode = { 'n', 'v' } },
      { '<leader>r',   group = 'Refactor',     mode = { 'n', 'v' } },
      { '<leader>t',   group = 'Database',     mode = { 'n', 'v' } },
      { '<leader>i',   group = 'Images',       mode = { 'n', 'v' } },
      { 'gr',          group = 'LSP Actions',  mode = { 'n', 'v' } },
      { '<leader>l',   group = 'Lists',        mode = { 'n', 'v' } },
      { '<leader>lq',  group = 'Quickfix',     mode = { 'n', 'v' } },
      { '<leader>ll',  group = 'Location',     mode = { 'n', 'v' } },
      { '<leader>c',   group = 'Code',         mode = { 'n', 'v' } },
      { '<leader>cm',  group = 'Molten',       mode = { 'n', 'v' } },
      { '<leader>cj',  group = 'Jupytext',     mode = { 'n', 'v' } },
      { '<leader>cmo', group = 'Output',       mode = { 'n', 'v' } },
    },
  },
  keys = {
    {
      '<leader>?',
      function() require('which-key').show({ global = false }) end,
      desc = 'Buffer keymaps',
    },
    {
      '<localleader>?',
      function() require('which-key').show({ global = false }) end,
      desc = 'Buffer keymaps',
    },
  },
}
