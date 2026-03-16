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
      { '<leader>f',  group = 'Telescope' },
      { '<leader>g',  group = 'Git' },
      { '<leader>j',  group = 'Java' },
      { '<leader>jt', group = 'Java Tests' },
      { '<leader>jx', group = 'Java Refactor' },
      { '<leader>r',  group = 'Search & Replace' },
      { '<leader>t',  group = 'Tests' },
      { '<leader>w',  group = 'Windows' },
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
