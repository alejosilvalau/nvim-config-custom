return {
  'nvim-java/nvim-java',
  config = function()
    require('java').setup()
    vim.lsp.enable('jdtls')
  end,
  keys = {
    -- Runner
    { '<leader>jr',  function() require('java').runner.built_in.run_app() end,     ft = 'java', desc = 'Run app' },
    { '<leader>js',  function() require('java').runner.built_in.stop_app() end,    ft = 'java', desc = 'Stop app' },
    { '<leader>jl',  function() require('java').runner.built_in.toggle_logs() end, ft = 'java', desc = 'Toggle logs' },
    -- Tests
    { '<leader>jtc', function() require('java').test.run_current_class() end,      ft = 'java', desc = 'Test class' },
    { '<leader>jtm', function() require('java').test.run_current_method() end,     ft = 'java', desc = 'Test method' },
    { '<leader>jta', function() require('java').test.run_all_tests() end,          ft = 'java', desc = 'Test all' },
    { '<leader>jtr', function() require('java').test.view_last_report() end,       ft = 'java', desc = 'Test report' },
    -- Refactor
    { '<leader>jxv', function() require('java').refactor.extract_variable() end,   ft = 'java', desc = 'Extract variable' },
    { '<leader>jxm', function() require('java').refactor.extract_method() end,     ft = 'java', desc = 'Extract method' },
    { '<leader>jxc', function() require('java').refactor.extract_constant() end,   ft = 'java', desc = 'Extract constant' },
    -- Misc
    { '<leader>jp',  function() require('java').profile.ui() end,                  ft = 'java', desc = 'Profiles' },
    { '<leader>jR',  function() require('java').settings.change_runtime() end,     ft = 'java', desc = 'Change JDK' },
  },
}
