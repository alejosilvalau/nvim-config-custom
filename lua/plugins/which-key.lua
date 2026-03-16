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
      { '<leader>jt', group = 'Java tests' },
      { '<leader>jx', group = 'Java refactor' },
      { '<leader>n',  group = 'Notes' },
      { '<leader>r',  group = 'Refactor' },
      { '<leader>t',  group = 'Database' },
      { '<leader>i',  group = 'Images' },
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
