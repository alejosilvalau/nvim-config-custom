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
      { '<leader>a',  group = 'AI' },
      { '<leader>b',  group = 'Buffers' },
      { '<leader>d',  group = 'Debug' },
      { '<leader>f',  group = 'Find' },
      { '<leader>j',  group = 'Java' },
      { '<leader>jt', group = 'Java tests' },
      { '<leader>je', group = 'Java extract' },
      { '<leader>n',  group = 'Notes' },
      { '<leader>r',  group = 'Refactor' },
      { '<leader>t',  group = 'Database' },
      { '<leader>i',  group = 'Images' },
      { 'gr',         group = 'LSP Actions' },
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
