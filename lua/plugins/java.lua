local function smart_run()
  local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
  if not client then
    vim.notify('No JDTLS client found', vim.log.levels.ERROR)
    return
  end

  local root = client.config.root_dir
  local module_info = vim.fn.glob(root .. '/src/**/module-info.java')

  if module_info ~= '' then
    -- Modular project
    local java = vim.fn.glob(vim.fn.stdpath('data') .. '/nvim-java/packages/openjdk/*/jdk-*/bin/java')
    client.request('workspace/executeCommand', { ---@diagnostic disable-line: param-type-mismatch
      command = 'vscode.java.resolveMainClass',
      arguments = { root },
    }, function(err, result) ---@diagnostic disable-line: param-type-mismatch
      if err or not result or #result == 0 then
        vim.notify('No main class found', vim.log.levels.ERROR)
        return
      end
      local choices = {}
      for _, item in ipairs(result) do
        table.insert(choices, item.mainClass)
      end
      vim.ui.select(choices, { prompt = 'Select main class:' }, function(choice)
        if not choice then return end
        vim.cmd('botright split | terminal ' .. java .. ' --module-path ' .. root .. '/bin -m ' .. choice)
      end)
    end)
  else
    -- Non-modular project
    require('java').runner.built_in.run_app({})
  end
end

return {
  'nvim-java/nvim-java',
  ft = 'java',
  dependencies = {
    'neovim/nvim-lspconfig',
    'JavaHello/spring-boot.nvim',
  },
  config = function()
    require('java').setup({})
    vim.lsp.config('jdtls', {
      root_dir = vim.fs.root(0, { ".project", "pom.xml", "gradle.build" }),
    })
    vim.lsp.enable('jdtls')

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == 'jdtls' then
          vim.notify('JDTLS ready', vim.log.levels.INFO)
        end
      end,
    })
  end,
  keys = {
    -- Runner
    { '<leader>jb',  function() require('java').build.build_workspace() end,       ft = 'java', desc = 'Build workspace' },
    { '<leader>jr',  smart_run,                                                    ft = 'java', desc = 'Run app' },
    { '<leader>js',  function() require('java').runner.built_in.stop_app() end,    ft = 'java', desc = 'Stop app' },
    { '<leader>jl',  function() require('java').runner.built_in.toggle_logs() end, ft = 'java', desc = 'Toggle logs' },

    -- Tests
    { '<leader>jtc', function() require('java').test.run_current_class() end,      ft = 'java', desc = 'Test class' },
    { '<leader>jtm', function() require('java').test.run_current_method() end,     ft = 'java', desc = 'Test method' },
    { '<leader>jta', function() require('java').test.run_all_tests() end,          ft = 'java', desc = 'Test all' },
    { '<leader>jtr', function() require('java').test.view_last_report() end,       ft = 'java', desc = 'Test report' },

    -- Debug tests via DAP-UI
    { '<leader>jtD', function() require('java').test.debug_current_class() end,    ft = 'java', desc = 'Debug class' },
    { '<leader>jtd', function() require('java').test.debug_current_method() end,   ft = 'java', desc = 'Debug method' },

    -- Refactor
    { '<leader>jev', function() require('java').refactor.extract_variable() end,   ft = 'java', desc = 'Extract variable' },
    { '<leader>jem', function() require('java').refactor.extract_method() end,     ft = 'java', desc = 'Extract method' },
    { '<leader>jec', function() require('java').refactor.extract_constant() end,   ft = 'java', desc = 'Extract constant' },

    -- Misc
    { '<leader>ji',  function() require('java').import.organize_imports() end,     ft = 'java', desc = 'Organize imports' },
    { '<leader>jc',  function() require('java').clean.workspace() end,             ft = 'java', desc = 'Clean workspace' },
    { '<leader>jp',  function() require('java').profile.ui() end,                  ft = 'java', desc = 'Profiles' },
    { '<leader>ji',  function() require('java').project.import_settings() end,     ft = 'java', desc = 'Import Settings' },
    { '<leader>jR',  function() require('java').settings.change_runtime() end,     ft = 'java', desc = 'Change JDK' },
  },
}
