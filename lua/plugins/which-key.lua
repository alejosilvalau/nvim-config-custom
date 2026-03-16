return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    preset = 'modern', -- 'default', 'modern', or 'helix'
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
      { '<leader>e',  group = 'Explorer' },
      { '<leader>f',  group = 'Find' },
      { '<leader>g',  group = 'Git' },
      { '<leader>j',  group = 'Java' },
      { '<leader>jt', group = 'Java Tests' },
      { '<leader>jx', group = 'Java Refactor' },
      { '<leader>n',  group = 'Notes' },
      { '<leader>r',  group = 'Refactor' },
      { '<leader>t',  group = 'Database' },
      { '<leader>u',  group = 'Undotree' },
      { '<leader>w',  group = 'Windows' },
      { '<leader>x',  group = 'Make Executable' },
      { '<leader>i',  group = 'Images' },
      { '<leader>n',  group = 'Notes' },
    },
  },
  keys = {
    {
      '<leader>?',
      function() require('which-key').show({ global = false }) end,
      desc = 'Buffer Local Keymaps (which-key)',
    },
    {
      '<localleader>?',
      function() require('which-key').show({ global = false }) end,
      desc = 'Buffer Local Keymaps (which-key)',
    },
  },
}
